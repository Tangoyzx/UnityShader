using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public static class CommandBufferShadowManager {
	private static List<CommandBufferShadowProjector> m_projectorList = new List<CommandBufferShadowProjector>();

	public static void AddProjector(CommandBufferShadowProjector projector) {
		m_projectorList.Add(projector);
	}

	public static void RemoveProjector(CommandBufferShadowProjector projector) {
		m_projectorList.Remove(projector);
	}

	public static List<CommandBufferShadowProjector> GetProjectorList() {

		return m_projectorList;
	}
}

public class CommandBufferShadowRenderer : MonoBehaviour {
	private Camera m_camera;
	private CommandBuffer m_commandBuffer;
	private Mesh m_cubeMesh;
	private Material m_material;
	void Awake () {
		m_material = new Material(Shader.Find("CommandBufferShadow/CommandBufferShadowDrawer"));
		var cubeGO = GameObject.CreatePrimitive(PrimitiveType.Cube);
		m_cubeMesh = cubeGO.GetComponent<MeshFilter>().sharedMesh;
		GameObject.Destroy(cubeGO);

		m_camera = GetComponent<Camera>();
		m_camera.depthTextureMode = DepthTextureMode.Depth;

		m_commandBuffer = new CommandBuffer();
		m_commandBuffer.name = "DrawOnScreen";

		m_camera.AddCommandBuffer(CameraEvent.BeforeImageEffects, m_commandBuffer);
	}

	void OnPreRender() {

		m_commandBuffer.Clear();
		foreach(var projector in CommandBufferShadowManager.GetProjectorList()) {
			m_commandBuffer.DrawMesh(m_cubeMesh, projector.GetCubeMatrix(), m_material, 0, 0, projector.GetMaterialPropertyBlock());
		}
	}
	
	private RenderTexture GetDepthTexture(int width, int height) {
		var rt = new RenderTexture(width, height, 24, RenderTextureFormat.Depth);
		rt.filterMode = FilterMode.Point;
		return rt;
	}

	private RenderTexture GetColorTexture(int width, int height) {
		var rt = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32);
		rt.filterMode = FilterMode.Bilinear;
		return rt;
	}
}
