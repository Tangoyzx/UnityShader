using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NoiseCreateRandomTree : MonoBehaviour {
	public GameObject prefab;
	// Use this for initialization
	void Start () {
		for(var i = 0; i < 1000; i++) {
			var rx = Random.Range(-30.0f, 30.0f);
			var rz = Random.Range(-10.0f, 70.0f);
			var tree = GameObject.Instantiate(prefab);
			tree.transform.position = new Vector3(rx, 0, rz);
		}
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
