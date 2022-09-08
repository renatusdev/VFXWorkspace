using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class NormalsStudy : MonoBehaviour
{
    MeshFilter m_MeshFilter;

    void Start()
    {
        m_MeshFilter = GetComponent<MeshFilter>();
    }

    void OnDrawGizmos()
    {
        m_MeshFilter = GetComponent<MeshFilter>();
        Vector3 worldOffset = transform.position;

        for(int i = 0; i < m_MeshFilter.mesh.normals.Length; i++)
        {
            Vector3 normal = m_MeshFilter.mesh.normals[i];
            Vector3 vertex = m_MeshFilter.mesh.vertices[i];

            Gizmos.DrawLine(vertex + worldOffset, vertex + normal + worldOffset);
        }
    }
}
