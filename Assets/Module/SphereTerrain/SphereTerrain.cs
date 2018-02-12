using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SphereTerrain : MonoBehaviour {
	public Material[] mats;
	public Transform target;
	public float radius;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		foreach(var mat in mats) {
			mat.SetVector("origin", target.position);
		}
	}
}
