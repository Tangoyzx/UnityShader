using UnityEngine;

[ExecuteInEditMode]
public class CBSDecal : MonoBehaviour
{
	public Material m_Material;

	public float size = 0.5f;
	public float far = 1;

	public Matrix4x4 cubeLocal;

	public void OnEnable()
	{
		CBSManager.instance.AddDecal (this);
	}

	public void Start()
	{
		CBSManager.instance.AddDecal (this);
		cubeLocal = Matrix4x4.identity;
		cubeLocal.m00 = far;
		cubeLocal.m03 = -0.5f * far;
		cubeLocal.m11 = size + size;
		cubeLocal.m22 = size + size;
	}

	public void OnDisable()
	{
		CBSManager.instance.RemoveDecal (this);
	}

	private void DrawGizmo(bool selected)
	{
		var col = new Color(0.0f,0.7f,1f,1.0f);
		col.a = selected ? 0.3f : 0.1f;
		Gizmos.color = col;
		Gizmos.matrix = transform.localToWorldMatrix;
		var center = new Vector3(-far * 0.5f, 0, 0);
		var boxSize = new Vector3(far, size + size, size + size);
		Gizmos.DrawCube (center, boxSize);
		col.a = selected ? 0.5f : 0.2f;
		Gizmos.color = col;
		Gizmos.DrawWireCube (center, boxSize);		
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
