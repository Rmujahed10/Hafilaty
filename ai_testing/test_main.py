import pandas as pd
import pytest
from clustering_only import run_capacitated_clustering


def make_students():
    return pd.DataFrame([
        {"StudentName": "A", "Latitude": 21.500, "Longitude": 39.200, "SchoolID": 34233},
        {"StudentName": "B", "Latitude": 21.501, "Longitude": 39.201, "SchoolID": 34233},
        {"StudentName": "C", "Latitude": 21.700, "Longitude": 39.400, "SchoolID": 34233},
        {"StudentName": "D", "Latitude": 21.701, "Longitude": 39.401, "SchoolID": 34233},
    ])


def test_empty_dataframe_returns_empty():
    df = pd.DataFrame(columns=["Latitude", "Longitude", "SchoolID"])
    result = run_capacitated_clustering(df, n_clusters=2, bus_capacity=2)
    assert result.empty


def test_busid_column_is_created():
    df = make_students()
    result = run_capacitated_clustering(df, n_clusters=2, bus_capacity=2)
    assert "BusID" in result.columns


def test_student_count_stays_the_same():
    df = make_students()
    result = run_capacitated_clustering(df, n_clusters=2, bus_capacity=2)
    assert len(result) == len(df)


def test_no_bus_exceeds_capacity():
    df = make_students()
    result = run_capacitated_clustering(df, n_clusters=2, bus_capacity=2)
    counts = result["BusID"].value_counts()
    assert (counts <= 2).all()


def test_handles_fewer_students_than_clusters():
    df = pd.DataFrame([
        {"StudentName": "A", "Latitude": 21.500, "Longitude": 39.200, "SchoolID": 34233}
    ])
    result = run_capacitated_clustering(df, n_clusters=3, bus_capacity=2)
    assert len(result) == 1
    assert "BusID" in result.columns


def test_bus_ids_are_valid():
    df = make_students()
    result = run_capacitated_clustering(df, n_clusters=2, bus_capacity=2)
    assert set(result["BusID"].unique()).issubset({0, 1})
    


def test_original_dataframe_not_modified():
    df = make_students()
    _ = run_capacitated_clustering(df, n_clusters=2, bus_capacity=2)
    assert "BusID" not in df.columns


def test_missing_latitude_or_longitude_raises_error():
    df = pd.DataFrame([
        {"StudentName": "A", "Latitude": 21.500, "SchoolID": 34233}
    ])
    with pytest.raises(ValueError):
        run_capacitated_clustering(df, n_clusters=2, bus_capacity=2)