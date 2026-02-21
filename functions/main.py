# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app

from firebase_functions import firestore_fn
from firebase_admin import initialize_app, firestore
import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from scipy.spatial.distance import cdist

# Initialize the Firebase Admin SDK
app = initialize_app()

def run_capacitated_clustering(df, n_clusters, bus_capacity):
    """The same logic from your notebook, adapted for the Cloud Function"""
    if df.empty:
        return df

    coords = df[['Latitude', 'Longitude']].values
    # Ensure we don't try to create more clusters than students
    actual_clusters = min(n_clusters, len(df))
    
    kmeans = KMeans(n_clusters=actual_clusters, random_state=42, n_init=10)
    df['BusID'] = kmeans.fit_predict(coords)
    centroids = kmeans.cluster_centers_
    
    # Balancing Loop
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

@firestore_fn.on_document_created(document="Students/{studentId}")
def on_student_enrolled(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """Triggered whenever a new document is added to the Students collection"""
    snapshot = event.data
    if not snapshot:
        return

    new_student_data = snapshot.to_dict()
    school_id = new_student_data.get("SchoolID")
    
    if not school_id:
        print("No SchoolID found in the new student document.")
        return

    db = firestore.client()

    # 1. Fetch all students for this specific school
    docs = db.collection("Students").where("SchoolID", "==", school_id).stream()
    students_data = []
    for doc in docs:
        d = doc.to_dict()
        d['doc_id'] = doc.id # Keep the document ID to update it later
        students_data.append(d)
    
    df = pd.DataFrame(students_data)

    # 2. Run Clustering (Example: 2 buses, capacity 50)
    # In a real app, you could fetch n_buses/capacity from a 'Schools' doc
    df_result = run_capacitated_clustering(df, n_clusters=2, bus_capacity=50)

    # 3. WRITE BACK TO FIRESTORE (Batch Update)
    batch = db.batch()

    # Update each student with their new BusID
    for _, row in df_result.iterrows():
        student_ref = db.collection("Students").document(row['doc_id'])
        batch.update(student_ref, {"BusID": int(row['BusID'])})

    # 4. Update the 'Buses' collection for the drivers
    # This groups students by their assigned BusID
    bus_groups = df_result.groupby('BusID')
    for bus_id, group in bus_groups:
        bus_doc_id = f"School_{school_id}_Bus_{int(bus_id)}"
        bus_ref = db.collection("Buses").document(bus_doc_id)
        
        bus_data = {
            "SchoolID": school_id,
            "BusNumber": int(bus_id),
            "StudentList": group['doc_id'].tolist(), # List of student IDs for driver
            "StudentNames": group['StudentName'].tolist() if 'StudentName' in group else [],
            "TotalStudents": len(group),
            "LastUpdated": firestore.SERVER_TIMESTAMP
        }
        batch.set(bus_ref, bus_data)

    batch.commit()
    print(f"Successfully re-clustered students for School {school_id}")