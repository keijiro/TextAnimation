using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.IO;

public class TextModelPostprocessor : AssetPostprocessor
{
    void OnPostprocessModel(GameObject go)
    {
        var filename = Path.GetFileNameWithoutExtension(assetPath);
        if (filename.ToLower().EndsWith("text"))
            foreach (var meshFilter in go.GetComponentsInChildren<MeshFilter>())
                ProcessMesh(meshFilter.sharedMesh);
    }

    static void ProcessMesh(Mesh mesh)
    {
        var ia_i = mesh.triangles;
        var vcount = ia_i.Length;

        // Split all the shared vertices.

        var va_o = new Vector3[vcount];
        var na_o = new Vector3[vcount];

        var va_i = mesh.vertices;
        var na_i = mesh.normals;

        for (var i = 0; i < vcount; i++)
        {
            var vi = ia_i[i];
            va_o[i] = va_i[vi];
            na_o[i] = na_i[vi];
        }

        mesh.vertices = va_o;
        mesh.normals = na_o;

        // UV0 - the centroid of the triangle
        // UV1 - the next vertex in the triangle
        // UV2 - the previous vertex in the triangle

        var uv0 = new List<Vector3>(vcount);
        var uv1 = new List<Vector3>(vcount);
        var uv2 = new List<Vector3>(vcount);

        for (var i = 0; i < vcount; i += 3)
        {
            var v0 = va_i[ia_i[i    ]];
            var v1 = va_i[ia_i[i + 1]];
            var v2 = va_i[ia_i[i + 2]];

            var center = (v0 + v1 + v2) / 3;

            uv0.Add(center);
            uv0.Add(center);
            uv0.Add(center);

            uv1.Add(v1);
            uv1.Add(v2);
            uv1.Add(v0);

            uv2.Add(v2);
            uv2.Add(v0);
            uv2.Add(v1);
        }

        mesh.SetUVs(0, uv0);
        mesh.SetUVs(1, uv1);
        mesh.SetUVs(2, uv2);

        // Rebuild all the triangles with the split vertices.

        var vi2 = 0;
        for (var smi = 0; smi < mesh.subMeshCount; smi++)
        {
            var sia_i = mesh.GetTriangles(smi);
            var sia_o = new int[sia_i.Length];
            for (var i = 0; i < sia_o.Length; i++) sia_o[i] = vi2++;
            mesh.SetTriangles(sia_o, smi);
        }
    }
}
