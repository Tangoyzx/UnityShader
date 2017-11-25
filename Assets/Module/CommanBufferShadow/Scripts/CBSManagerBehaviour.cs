using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;

public class CBSManager
{
	static CBSManager m_Instance;
	static public CBSManager instance {
		get {
			if (m_Instance == null)
				m_Instance = new CBSManager();
			return m_Instance;
		}
	}

	internal HashSet<CBSDecal> _decalList = new HashSet<CBSDecal>();

	public void AddDecal (CBSDecal d)
	{
		RemoveDecal (d);
		_decalList.Add(d);
	}
	public void RemoveDecal (CBSDecal d)
	{
		_decalList.Remove(d);
	}
}

[ExecuteInEditMode]
public class CBSManagerBehaviour : MonoBehaviour
{
	public Mesh m_CubeMesh;
	private CommandBuffer _shadowCB;
	private Camera _camera;

	void Awake() {
		_shadowCB = new CommandBuffer();
		_shadowCB.name = "CommandBufferShadow";

		_camera = Camera.main;
		_camera.AddCommandBuffer(CameraEvent.BeforeLighting, _shadowCB);
	}

	public void OnWillRenderObject()
	{
		_shadowCB.Clear();
		var manager = CBSManager.instance;

		var normalsID = Shader.PropertyToID("_NormalsCopy");
		_shadowCB.GetTemporaryRT (normalsID, -1, -1);
		_shadowCB.Blit (BuiltinRenderTextureType.GBuffer2, normalsID);
		
		_shadowCB.SetRenderTarget (BuiltinRenderTextureType.GBuffer0, BuiltinRenderTextureType.CameraTarget);
		foreach (var decal in manager._decalList)
		{
			_shadowCB.DrawMesh (m_CubeMesh, decal.transform.localToWorldMatrix * decal.cubeLocal, decal.m_Material);
		}
		_shadowCB.ReleaseTemporaryRT (normalsID);
	}
}
