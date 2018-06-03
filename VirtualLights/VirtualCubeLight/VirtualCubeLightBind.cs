using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VirtualCubeLightBind : MonoBehaviour
{
    public Vector3 extents;
    public Material material;


    void Update()
    {
        var pOrigin = transform.position + transform.rotation * new Vector3(-extents.x, -extents.y, -extents.z);
        var pX = transform.position + transform.rotation * new Vector3(extents.x, -extents.y, -extents.z);
        var pY = transform.position + transform.rotation * new Vector3(-extents.x, extents.y, -extents.z);
        var pZ = transform.position + transform.rotation * new Vector3(-extents.x, -extents.y, extents.z);

        material.SetVector("_CubeLight_Origin", pOrigin);
        material.SetVector("_CubeLight_PX", pX);
        material.SetVector("_CubeLight_PY", pY);
        material.SetVector("_CubeLight_PZ", pZ);
    }

    void OnDrawGizmos()
    {
        var cacheMatrix = Gizmos.matrix;
        var cacheColor = Gizmos.color;

        Gizmos.matrix = transform.localToWorldMatrix;

        Gizmos.DrawWireCube(Vector3.zero, extents * 2f);

        Gizmos.color = cacheColor;
        Gizmos.matrix = cacheMatrix;
    }
}
