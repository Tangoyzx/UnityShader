using System.Collections;
using System.Collections.Generic;
using UnityEngine.Rendering;
using UnityEngine;

namespace CommandBufferShadow {
	public class CBManager : MonoBehaviour {
		private static CBManager _instance;
		public static CBManager instance {
			get {return _instance;}
		}
		public Material shadowMat;

		public Vector3 lightWorldDir;
		public RenderTexture rt1;
		public RenderTexture rt2;
		private List<CBShadow> _shadowList;
		private Camera _camera;

		void Awake() {
			this.shadowMat = new Material(Shader.Find("CommandBufferShadow/ShadowShader"));
			this._shadowList = new List<CBShadow>();

			_camera = GetComponent<Camera>();

			lightWorldDir = lightWorldDir.normalized;

			rt1 = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
			rt2 = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth);
			Graphics.SetRenderTarget(rt1.colorBuffer, rt2.depthBuffer);
			
			_instance = this;
		}
		public void AddCommandBuffer(CBShadow cbShadow) {
			_shadowList.Add(cbShadow);
		}

		public void OnPreRender() {

		}
	}
}