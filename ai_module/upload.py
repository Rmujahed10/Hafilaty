import pandas as pd
from firebase_admin import credentials, firestore, initialize_app

# 1. Initialize Firebase
cred = credentials.Certificate('serviceAccountKey.json')
initialize_app(cred)
db = firestore.client()

# 2. Load Excel
df = pd.read_excel('STUDENTDATASET.xlsx', sheet_name='Students')

def upload_data(df):
    batch = db.batch()
    count = 0
    total = 0
    
    print(f"Uploading {len(df)} students...")
    
    for _, row in df.iterrows():
        stu_id = str(row['StudentID']).strip()
        doc_ref = db.collection('Students').document(stu_id)
        
        data = {
            "StudentName": row['StudentName'],
            "SchoolID": int(row['SchoolID']),
            "Latitude": float(row['Latitude']),
            "Longitude": float(row.get('Longitude', row.get('Longtitude'))),
            "StudentID": stu_id,
            "BusID": ""
        }
        
        batch.set(doc_ref, data)
        count += 1
        total += 1
        
        if count >= 400:
            batch.commit()
            print(f"Committed {total} records...")
            batch = db.batch()
            count = 0
            
    batch.commit()
    print(f"Finished! {total} students uploaded.")

upload_data(df)