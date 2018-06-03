using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VirtualSpotLightBind : MonoBehaviour
{
    public Material material;


    void Update()
    {
        material.SetVector("_VirtualLightPos", transform.position);
        material.SetVector("_VirtualLightForward", transform.forward);
    }
}
