using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


namespace CommandBufferShadow {
	[DisallowMultipleComponent]
	public class CBShadow : MonoBehaviour {
		public int rtSize = 256;
		public float size = 5.0f;
		public float far = 5.0f;
		public RenderTexture rt;
		public Transform root;
		private CommandBuffer _shadowCB;
		private Renderer[] _rendererList;
		void Start() {
			rt = new RenderTexture(rtSize, rtSize, 16, RenderTextureFormat.Depth);
			_shadowCB = new CommandBuffer();
			_shadowCB.name = "ShadowCommandBuffer";
			_rendererList = root.GetComponentsInChildren<Renderer>();
		}

		void OnRenderObject() {
			var halfSize = size * 0.5f;
			var projection = Matrix4x4.Ortho(-halfSize, halfSize, -halfSize, halfSize, 0, far);
			var viewMat = this.transform.worldToLocalMatrix;
			viewMat.m22 = -viewMat.m22;
			_shadowCB.Clear();
			
			_shadowCB.SetRenderTarget(rt);
			_shadowCB.ClearRenderTarget(true, true, Color.black, 1);
			_shadowCB.SetViewProjectionMatrices(viewMat, projection);
			for(var i=0; i < _rendererList.Length; i++) {
				_shadowCB.DrawRenderer(_rendererList[i], CBManager.instance.shadowMat);
			}
			Graphics.ExecuteCommandBuffer(_shadowCB);
		}

		void OnDrawGizmos() {
			var orgMatrix = Gizmos.matrix;
			Gizmos.matrix = this.transform.localToWorldMatrix;
			Gizmos.DrawWireCube(new Vector3(0, 0, far * 0.5f), new Vector3(size, size, far));
			Gizmos.matrix = orgMatrix;
		}
	}
}