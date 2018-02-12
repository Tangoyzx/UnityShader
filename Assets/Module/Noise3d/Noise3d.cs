using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Noise3d : MonoBehaviour {
	private const int SIZE = 8;
	private const int PIECE = 2;
	private const int TOTAL_1 = 32;
	private const int TOTAL_2 = 16;
	private const int TOTAL_12 = TOTAL_1 * TOTAL_2;
	public Texture3D tex3d;
	public Material mat;

	private Vector3[] gradientVectorList;
	private int[] perms;
	void Start () {
		GetGradientVectors(out gradientVectorList, out perms);
		tex3d = new Texture3D(SIZE, SIZE, SIZE, TextureFormat.RFloat, false);
		tex3d.filterMode = FilterMode.Bilinear;

		var colors = new Color[SIZE * SIZE * SIZE];
		int PER = SIZE / PIECE;

		for(var i = 0; i < SIZE; i++) {
			for(var j = 0; j < SIZE; j++) {
				for(var k = 0; k < SIZE; k++) {
					var v = GetNoise((float)i / PIECE, (float)j / PIECE, (float)k / PIECE, PER) + 0.5f;
				colors[i * SIZE * SIZE + j * SIZE + k] = new Color(v, 0, 0, 1);
				}
			}
		}

		tex3d.SetPixels(colors);
		tex3d.Apply();
		mat.SetTexture("_Noise", tex3d);
	}
	
	float GetNoise(float x, float y, float z, int per) {
		var gx = (int)x;
		var gy = (int)y;
		var gz = (int)z;

		return Surflet(x, y, z, gx, gy, gz, per) + Surflet(x, y, z, gx, gy, gz+1, per) + 
			   Surflet(x, y, z, gx, gy+1, gz, per) + Surflet(x, y, z, gx, gy+1, gz+1, per) + 
			   Surflet(x, y, z, gx+1, gy, gz, per) + Surflet(x, y, z, gx+1, gy, gz+1, per) + 
			   Surflet(x, y, z, gx+1, gy+1, gz, per) + Surflet(x, y, z, gx+1, gy+1, gz+1, per);
	}

	float Surflet(float x, float y, float z, int gx, int gy, int gz, int per) {
		float distX = Mathf.Abs(gx - x);
		float distY = Mathf.Abs(gy - y);
		float distZ = Mathf.Abs(gz - z);
		float polyX = 1 - 6 * distX * distX * distX * distX * distX + 15 * distX * distX * distX * distX - 10 * distX * distX * distX;
		float polyY = 1 - 6 * distY * distY * distY * distY * distY + 15 * distY * distY * distY * distY - 10 * distY * distY * distY;
		float polyZ = 1 - 6 * distZ * distZ * distZ * distZ * distZ + 15 * distZ * distZ * distZ * distZ - 10 * distZ * distZ * distZ;
		int randomIndex = perms[(perms[(perms[gx%per] + gy % per) % TOTAL_12]  + gz % per) % TOTAL_12];
		var v = gradientVectorList[randomIndex];
		float xx = v.x * (x - gx) + v.y * (y - gy) + v.z * (z - gz);
		return xx * polyX * polyY * polyZ;
	}

	void GetGradientVectors(out Vector3[] gradientVectorList, out int[] perms) {
		UnityEngine.Random.seed = (int)DateTime.Now.Ticks;
		
		gradientVectorList = new Vector3[TOTAL_1 * TOTAL_2];

		for(var i = 0; i < TOTAL_1; i++) {
			var angle1 = Mathf.PI * 2.0f * i / TOTAL_1 + 0.5f / TOTAL_1;
			for(var j = 0; j < TOTAL_2; j++) {
				var angle2 = Mathf.PI * j / TOTAL_2 - Mathf.PI * (0.5f-0.5f/TOTAL_2);
				var dy = Mathf.Sin(angle2);
				var ss = Mathf.Cos(angle2);
				var dz = ss * Mathf.Cos(angle1);
				var dx = ss * Mathf.Sin(angle1);
				gradientVectorList[i * TOTAL_2 + j] = new Vector3(dx, dy, dz);
			}
		}

		perms = new int[TOTAL_1 * TOTAL_2];
		for(var i = 0; i < perms.Length; i++) {
			perms[i] = i;
		}

		for(var i = 0; i < perms.Length; i++) {
			var randomI = UnityEngine.Random.Range(0, perms.Length);
			if (i != randomI) {
				var tmp = perms[i];
				perms[i] = perms[randomI];
				perms[randomI] = tmp;			
			}
		}
	}
}
