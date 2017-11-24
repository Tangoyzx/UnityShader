using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class PlanarShadow : MonoBehaviour {
	public Transform pointLight;
	private Shader planarShadowShader;
	private CommandBuffer _cb;
	private Material _mat;
	void Start () {
		_mat = new Material(Shader.Find("PlanarShadow/PlanarShadow"));
		_cb = new CommandBuffer();
		_cb.name = "PlanarShadow";
		foreach(var renderer in GetComponentsInChildren<Renderer>()) {
			_cb.DrawRenderer(renderer, _mat);
		}

		Camera.main.AddCommandBuffer(CameraEvent.AfterForwardOpaque, _cb);
	}

	void Update() {
		var lightPos = pointLight.position;
		_mat.SetVector("_Light", new Vector4(lightPos.x, lightPos.y, lightPos.z, 1));
	}
}
