using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CommandBufferShadowProjector : MonoBehaviour {
	public float size;
	public float far;

	public RenderTexture renderTexture;
	public Transform rendererRoot;
	public Shader shadowShader;
	private Material shadowMaterial;
	private MaterialPropertyBlock m_materialPropertyBlock;
	private CommandBuffer m_commandBuffer;
	private Renderer[] m_rendererList;
	private Matrix4x4 m_viewMatrix;
	private Matrix4x4 m_projMatrix;
	private Matrix4x4 m_glProjMatrix;

	private Matrix4x4 m_cubeMatrix;
	// Use this for initialization
	void Start () {
		shadowMaterial = new Material(shadowShader);
		m_rendererList = rendererRoot.GetComponentsInChildren<Renderer>();

		renderTexture = new RenderTexture(256, 256, 16, RenderTextureFormat.Depth);
		m_commandBuffer = new CommandBuffer();
		m_commandBuffer.name = "DrawShadow";	

		m_materialPropertyBlock = new MaterialPropertyBlock();
	
		Camera.main.AddCommandBuffer(CameraEvent.AfterForwardOpaque, m_commandBuffer);

		CommandBufferShadowManager.AddProjector(this);
	}
	

	public Matrix4x4 GetViewMatrix() {
		return m_viewMatrix;
	}

	public Matrix4x4 GetProjMatrix() {
		return m_projMatrix;
	}

	public Matrix4x4 GetCubeMatrix() {
		return m_cubeMatrix;
	}

	public Renderer[] GetRendererList() {
		return m_rendererList;
	}

	public MaterialPropertyBlock GetMaterialPropertyBlock() {
		return m_materialPropertyBlock;
	}


	void Update() {
		var rendererBounds = GetRenderersBounds(m_rendererList);
		var cubeMatrix = Matrix4x4.identity;
		cubeMatrix.m00 = rendererBounds.size.x;
		cubeMatrix.m11 = rendererBounds.size.y;
		cubeMatrix.m22 = rendererBounds.size.z;
		cubeMatrix.m03 = rendererBounds.center.x;
		cubeMatrix.m13 = rendererBounds.center.y;
		cubeMatrix.m23 = rendererBounds.center.z;
		m_cubeMatrix = transform.localToWorldMatrix * cubeMatrix;

		m_viewMatrix = transform.worldToLocalMatrix;
		m_viewMatrix.SetRow(2, -m_viewMatrix.GetRow(2));

		var rendererMin = rendererBounds.min;
		var rendererMax = rendererBounds.max;
		m_projMatrix = Matrix4x4.Ortho(rendererMin.x, rendererMax.x, rendererMin.y, rendererMax.y, rendererMin.z, rendererMax.z);
		m_glProjMatrix = GL.GetGPUProjectionMatrix(m_projMatrix, true);

		m_materialPropertyBlock.SetMatrix("_ShadowVP", m_glProjMatrix * m_viewMatrix);
		m_materialPropertyBlock.SetTexture("_ShadowTex", renderTexture);
		m_materialPropertyBlock.SetVector("_ShadowCameraParams", new Vector4(rendererMin.z, rendererMax.z, 0, 0));

		m_commandBuffer.Clear();
		m_commandBuffer.SetRenderTarget(renderTexture);
		m_commandBuffer.ClearRenderTarget(true, true, new Color(0, 0, 0, 0));
		m_commandBuffer.SetViewProjectionMatrices(m_viewMatrix, m_projMatrix);
		foreach(var renderer in m_rendererList) {
			m_commandBuffer.DrawRenderer(renderer, shadowMaterial);
		}
	}

	void DrawGizmo(bool selected)
	{
		var bounds = GetRenderersBounds();
		
		var cubeMatrix = Matrix4x4.identity;
		cubeMatrix.m00 = bounds.size.x;
		cubeMatrix.m11 = bounds.size.y;
		cubeMatrix.m22 = bounds.size.z;
		cubeMatrix.m03 = bounds.center.x;
		cubeMatrix.m13 = bounds.center.y;
		cubeMatrix.m23 = bounds.center.z;
		var col = new Color(0.0f,0.7f,1f,1.0f);
		col.a = selected ? 0.3f : 0.1f;
		Gizmos.color = col;
		Gizmos.matrix = transform.localToWorldMatrix * cubeMatrix;
		Gizmos.DrawCube (Vector3.zero, Vector3.one);
		col.a = selected ? 0.5f : 0.2f;
		Gizmos.color = col;
		Gizmos.DrawWireCube (Vector3.zero, Vector3.one);		
	}

	private Bounds GetRenderersBounds(Renderer[] rendererList = null) {
		// *****************************
		// 开始计算所有Renderer节点的AABB
		// *****************************
		if (rendererList == null) {
			rendererList = GetComponentsInChildren<Renderer>();
		}
		var maxP = new Vector3(float.MinValue, float.MinValue, float.MinValue);
		var minP = new Vector3(float.MaxValue, float.MaxValue, float.MaxValue);

		var m = transform.worldToLocalMatrix;
		// 多次使用到矩阵中各位的符号，先存起来
		var signs = new Vector3[3];
		for (var i = 0; i < 3; i++) {
			var rowData = m.GetRow(i);
			signs[i].x = Mathf.Sign(rowData.x);
			signs[i].y = Mathf.Sign(rowData.y);
			signs[i].z = Mathf.Sign(rowData.z);
		}
		
		foreach(var renderer in rendererList) {
			var bounds = renderer.bounds;
			var rCenter = bounds.center;
			var rExtents = bounds.extents;
			float maxX, minX, maxY, minY, maxZ, minZ;
			CountBoundsMaxMin(m.GetRow(0), signs[0], rCenter, rExtents, out maxX, out minX);
			CountBoundsMaxMin(m.GetRow(1), signs[1], rCenter, rExtents, out maxY, out minY);
			CountBoundsMaxMin(m.GetRow(2), signs[2], rCenter, rExtents, out maxZ, out minZ);

			maxP = Vector3.Max(maxP, new Vector3(maxX, maxY, maxZ));
			minP = Vector3.Min(minP, new Vector3(minX, minY, minZ));		
		}
		// *****************************
		// maxP和minP组成所有Renderer的总AABB碰撞盒
		// *****************************

		var center = (maxP + minP) * 0.5f;
		var size = maxP - minP;

		if (size.x > size.y) 
			size.y = size.x;
		else
			size.x = size.y;

		// 假如方向朝下，还需要处理朝向地面的长度，因为影子最终要投影到地上。
		if (transform.forward.y < 0) {
			var localToWorldYAxis = transform.localToWorldMatrix.GetRow(1);
			var halfSize = size.x * 0.5f;
			// 同理于AABB转换，只是这次只需要算出最高的Y
			var maxY = (center.x + Mathf.Sign(localToWorldYAxis.x) * halfSize) * localToWorldYAxis.x +
						(center.y + Mathf.Sign(localToWorldYAxis.y) * halfSize) * localToWorldYAxis.y +
						+ localToWorldYAxis.w;
			// 根据相似三角形可以算出最高的顶点到地面的距离
			var toGroundZ = maxY / -transform.forward.y;

			// 假如距离比原碰撞盒长，那就延长
			if (toGroundZ > maxP.z) {
				size.z = toGroundZ - minP.z;
				center.z = minP.z + size.z * 0.5f;
			}
		}

		// 稍微加长一点
		var offset = 0.0f;
		var zStart = center.z - size.z * 0.5f;
		size.z = Mathf.Min(size.z + offset, 20);
		center.z = zStart + size.z * 0.5f;

		return new Bounds(center, size);
	}

	private void CountBoundsMaxMin(Vector4 rowData, Vector3 rowSign, Vector3 center, Vector3 extents, out float max, out float min) {
        max = (center.x + rowSign.x * extents.x) * rowData.x + (center.y + rowSign.y * extents.y) * rowData.y + (center.z + rowSign.z * extents.z) * rowData.z + rowData.w;
        min = (center.x - rowSign.x * extents.x) * rowData.x + (center.y - rowSign.y * extents.y) * rowData.y + (center.z - rowSign.z * extents.z) * rowData.z + rowData.w;
    }

	public void OnDrawGizmos()
	{
		DrawGizmo(false);
	}
	public void OnDrawGizmosSelected()
	{
		DrawGizmo(true);
	}
}
