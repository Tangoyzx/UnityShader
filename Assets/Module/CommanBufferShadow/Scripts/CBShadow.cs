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
		public Transform root;
		private Renderer[] _rendererList;
		private Matrix4x4 _projectionMatrix;
		private Matrix4x4 _localCubeMatrix;
		void Start() {
			_rendererList = root.GetComponentsInChildren<Renderer>();

			var halfSize = size * 0.5f;
			_projectionMatrix = Matrix4x4.Ortho(-halfSize, halfSize, -halfSize, halfSize, 0, far);

			_localCubeMatrix = Matrix4x4.identity;
			_localCubeMatrix.m00 = size;
			_localCubeMatrix.m11 = size;
			_localCubeMatrix.m22 = far;
			_localCubeMatrix.m23 = far * 0.5f;

			CBManager.instance.AddShadow(this);
		}

		void OnDrawGizmos() {
			var orgMatrix = Gizmos.matrix;
			Gizmos.matrix = this.transform.localToWorldMatrix;
			Gizmos.DrawWireCube(new Vector3(0, 0, far * 0.5f), new Vector3(size, size, far));
			Gizmos.matrix = orgMatrix;
		}

		public Matrix4x4 GetViewMatrix()
		{
			var viewMat = this.transform.worldToLocalMatrix;
			// Shader中的view space的z是负数的。
			viewMat.m22 = -viewMat.m22;
			viewMat.m23 = -viewMat.m23;
			return viewMat;
		}

		public Matrix4x4 GetProjectionMatrix() {
			return _projectionMatrix;
		}

		public Matrix4x4 GetCubeMatrix() {
			return _localCubeMatrix;
		}

		public Renderer[] GetShadowRenderers() {
			return _rendererList;
		}
	}
}