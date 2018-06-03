using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VirtualPointLightBind : MonoBehaviour
{
    public Material material;


    void Update()
    {
        material.SetVector("_VirtualLightPos", transform.position);
    }
}
