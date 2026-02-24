# Deploy with `firebase deploy --only functions`

from firebase_functions import firestore_fn
from firebase_admin import initialize_app, firestore
import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from scipy.spatial.distance import cdist
from firebase_functions.options import set_global_options

# Set the global memory to 512MiB to handle Pandas/Sklearn overhead
set_global_options(memory=512)

# Initialize the Firebase Admin SDK
app = initialize_app()

def run_capacitated_clustering(df, n_clusters, bus_capacity):
    """Core AI Logic: Groups students by location with capacity limits"""
    if df.empty:
        return df

    coords = df[['Latitude', 'Longitude']].values
    actual_clusters = min(n_clusters, len(df))
    
    kmeans = KMeans(n_clusters=actual_clusters, random_state=42, n_init=10)
    df['BusID'] = kmeans.fit_predict(coords)
    centroids = kmeans.cluster_centers_
    
    while True:
        counts = df['BusID'].value_counts()
        overloaded = counts[counts > bus_capacity].index.tolist()
        underloaded = counts[counts < bus_capacity].index.tolist()
        
        if not overloaded or not underloaded:
            break
            
        for bus_id in overloaded:
            bus_indices = df[df['BusID'] == bus_id].index
            distances = cdist(df.loc[bus_indices, ['Latitude', 'Longitude']], [centroids[bus_id]]).flatten()
            furthest_idx = bus_indices[np.argmax(distances)]

            student_loc = df.loc[[furthest_idx], ['Latitude', 'Longitude']]
            dist_to_others = cdist(student_loc, [centroids[b] for b in underloaded]).flatten()
            new_bus_id = underloaded[np.argmin(dist_to_others)]
            
            df.at[furthest_idx, 'BusID'] = new_bus_id
    return df

def reoptimize_school_routes(school_id):
    """Helper Function: Cleans old data and re-calculates bus assignments"""
    db = firestore.client()

    # --- DATA TYPE FIX ---
    # Firestore Document Paths REQUIRE a string.
    # Firestore Queries (where) REQUIRE the exact type in the DB (int).
    doc_path_id = str(school_id)
    try:
        numeric_search_id = int(school_id)
    except (ValueError, TypeError):
        numeric_search_id = school_id

    # 1. Fetch School Config using the string path
    school_ref = db.collection("Schools").document(doc_path_id).get()
    if not school_ref.exists:
        print(f"School document '{doc_path_id}' not found.")
        return
    
    config = school_ref.to_dict()
    n_buses = config.get("BusCount", 2)
    capacity = config.get("BusCapacity", 50)

    # 2. Fetch all current students using the numeric ID
    docs = db.collection("Students").where("SchoolID", "==", numeric_search_id).stream()
    students_data = []
    student_refs = [] 
    for doc in docs:
        d = doc.to_dict()
        d['doc_id'] = doc.id 
        students_data.append(d)
        student_refs.append(doc.reference)
    
    if not students_data:
        print(f"No students found for numeric SchoolID: {numeric_search_id}")
        return

    df = pd.DataFrame(students_data)

    # 3. Run AI Clustering
    df_result = run_capacitated_clustering(df, n_clusters=n_buses, bus_capacity=capacity)

    # 4. Atomic Cleanup and Update (Max 500 operations)
    batch = db.batch()

    # STEP A: Delete ALL old Bus documents for this school
    old_buses = db.collection("Buses").where("SchoolID", "==", numeric_search_id).stream()
    for bus_doc in old_buses:
        batch.delete(bus_doc.reference)

    # STEP B: Clear old BusID assignments from all students
    for ref in student_refs:
        batch.update(ref, {"BusID": firestore.DELETE_FIELD})

    # 5. Create NEW assignments and Bus Manifests
    bus_groups = df_result.groupby('BusID')
    for bus_idx, group in bus_groups:
        # Simple Unique ID (Starting at 101)
        friendly_bus_number = int(bus_idx) + 101
        bus_doc_id = f"Bus_{numeric_search_id}_{friendly_bus_number}"
        
        unique_student_ids = list(set(group['doc_id'].tolist()))

        # Update Student documents with the new friendly ID
        for doc_id in unique_student_ids:
            student_ref = db.collection("Students").document(doc_id)
            batch.update(student_ref, {"BusID": str(friendly_bus_number)})

        # Create the Bus manifest
        bus_ref = db.collection("Buses").document(bus_doc_id)
        batch.set(bus_ref, {
            "SchoolID": numeric_search_id,
            "BusNumber": friendly_bus_number,
            "StudentList": unique_student_ids,
            "StudentNames": list(set(group['StudentName'].tolist())) if 'StudentName' in group else [],
            "TotalStudents": len(unique_student_ids),
            "LastUpdated": firestore.SERVER_TIMESTAMP
        })

    batch.commit()
    print(f"Clean optimization successful for school {numeric_search_id}. IDs start at 101.")

# --- TRIGGERS ---

@firestore_fn.on_document_created(document="Students/{studentId}")
def on_student_added(event):
    school_id = event.data.to_dict().get("SchoolID")
    if school_id: reoptimize_school_routes(school_id)

@firestore_fn.on_document_deleted(document="Students/{studentId}")
def on_student_deleted(event):
    # event.data contains the snapshot of the document BEFORE it was deleted
    school_id = event.data.to_dict().get("SchoolID")
    if school_id: reoptimize_school_routes(school_id)

@firestore_fn.on_document_updated(document="Schools/{schoolId}")
def on_fleet_changed(event):
    school_id = event.data.after.id
    reoptimize_school_routes(school_id)