import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from scipy.spatial.distance import cdist


def run_capacitated_clustering(df, n_clusters, bus_capacity):
    """
    Groups students by location and rebalances clusters
    so no bus exceeds the maximum capacity.
    """
    if df.empty:
        return df.copy()

    df = df.copy()

    required_columns = {"Latitude", "Longitude"}
    missing = required_columns - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    coords = df[["Latitude", "Longitude"]].values
    actual_clusters = min(n_clusters, len(df))

    kmeans = KMeans(n_clusters=actual_clusters, random_state=42, n_init=10)
    df["BusID"] = kmeans.fit_predict(coords)
    centroids = kmeans.cluster_centers_

    while True:
        counts = df["BusID"].value_counts()
        overloaded = counts[counts > bus_capacity].index.tolist()
        underloaded = counts[counts < bus_capacity].index.tolist()

        if not overloaded or not underloaded:
            break

        for bus_id in overloaded:
            bus_indices = df[df["BusID"] == bus_id].index

            distances = cdist(
                df.loc[bus_indices, ["Latitude", "Longitude"]],
                [centroids[bus_id]]
            ).flatten()

            furthest_idx = bus_indices[np.argmax(distances)]

            student_loc = df.loc[[furthest_idx], ["Latitude", "Longitude"]]
            dist_to_others = cdist(
                student_loc,
                [centroids[b] for b in underloaded]
            ).flatten()

            new_bus_id = underloaded[np.argmin(dist_to_others)]
            df.at[furthest_idx, "BusID"] = new_bus_id

    return df