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
		private CommandBuffer _shadowCommandBuffer;
		private Mesh _cube;
		public RenderTexture _shadowRT;
		public RenderTexture _shadowDT;
		private Material _drawShadowMaterial;
		public RenderTexture _screenColorRT;
		public RenderTexture _screenDepthRT;

		private RenderTexture _activeRT;

		void Awake() {
			_activeRT = RenderTexture.active;

			_screenColorRT = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
			_screenDepthRT = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth);

			Graphics.SetRenderTarget(_screenColorRT.colorBuffer, _screenDepthRT.depthBuffer);
			this._drawShadowMaterial = new Material(Shader.Find("CommandBufferShadow/DrawShadowShader"));
			this.shadowMat = new Material(Shader.Find("CommandBufferShadow/ShadowShader"));
			this._shadowList = new List<CBShadow>();

			_camera = GetComponent<Camera>();
			_camera.depthTextureMode = DepthTextureMode.DepthNormals;

			lightWorldDir = lightWorldDir.normalized;

			_shadowCommandBuffer = new CommandBuffer();
			_shadowCommandBuffer.name = "ShadowCommandBuffer";

			var cubeGO = GameObject.CreatePrimitive(PrimitiveType.Cube);
			_cube = cubeGO.GetComponent<MeshFilter>().mesh;
			GameObject.Destroy(cubeGO);
			
			_camera.AddCommandBuffer(CameraEvent.AfterForwardOpaque, _shadowCommandBuffer);
			_camera.SetTargetBuffers(_screenColorRT.colorBuffer, _screenDepthRT.depthBuffer);

			_shadowRT = new RenderTexture(256, 256, 0, RenderTextureFormat.ARGB32);
			_shadowDT = new RenderTexture(256, 256, 16, RenderTextureFormat.Depth);

			_instance = this;
		}
		public void AddShadow(CBShadow cbShadow) {
			_shadowList.Add(cbShadow);
		}

		public void OnPreRender() {
			
			_shadowCommandBuffer.Clear();
			var activeRT = RenderTexture.active;
			var orgCB = Graphics.activeColorBuffer;
			var orgDB = Graphics.activeDepthBuffer;
			
			var mpb = new MaterialPropertyBlock();
			var shadowVP_ID = Shader.PropertyToID("_shadowVP");
			var MainTex_ID = Shader.PropertyToID("_MainTex");
			

			for(var i = 0; i < _shadowList.Count; i++)
			{
				var shadow = _shadowList[i];
				var shadowViewMatrix = shadow.GetViewMatrix();
				var shadowProjectionMatrix = GL.GetGPUProjectionMatrix(shadow.GetProjectionMatrix(), true);
				_shadowCommandBuffer.SetRenderTarget(_shadowDT.depthBuffer);
				_shadowCommandBuffer.ClearRenderTarget(true, true, Color.black);
				_shadowCommandBuffer.SetViewProjectionMatrices(shadowViewMatrix, shadowProjectionMatrix);
				
				var renderers = shadow.GetShadowRenderers();
				foreach(var renderer in renderers)
				 {
					 _shadowCommandBuffer.DrawRenderer(renderer, shadowMat);
				 }
				
				_shadowCommandBuffer.SetRenderTarget(_screenColorRT.colorBuffer, _screenDepthRT.depthBuffer);
				_shadowCommandBuffer.SetViewProjectionMatrices(_camera.worldToCameraMatrix, _camera.projectionMatrix);
				
				
				var cubeMatrix = shadow.transform.localToWorldMatrix * shadow.GetCubeMatrix();
				var shadowVP = GL.GetGPUProjectionMatrix(shadowProjectionMatrix, true) * shadowViewMatrix;
				
				
				var dp = renderers[0].transform.position;
				var pp = shadowVP * new Vector4(dp.x, dp.y, dp.z, 1);
				
				
				mpb.SetMatrix(shadowVP_ID, shadowVP);
				mpb.SetTexture(MainTex_ID, _shadowDT);
				_shadowCommandBuffer.DrawMesh(_cube, cubeMatrix, _drawShadowMaterial, 0, 0, mpb);
			}
		}

		public void OnPostRender() {
			Graphics.SetRenderTarget(_activeRT);
			Graphics.Blit(_screenColorRT, RenderTexture.active);
		}
	}
}