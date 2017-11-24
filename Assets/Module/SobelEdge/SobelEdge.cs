using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SobelEdge : MonoBehaviour {
	private Material _mat;
	void Awake() {
		_mat = new Material(Shader.Find("SobelEdge/SobelEdge"));
	}
	void OnRenderImage(RenderTexture src, RenderTexture dst) {
		Graphics.Blit(src, dst, _mat);
	}
}
