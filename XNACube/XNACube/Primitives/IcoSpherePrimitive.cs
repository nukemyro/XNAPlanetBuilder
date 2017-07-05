using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace XNACube
{
    public class IcoSpherePrimitive : IcosahedronPrimitive
    {
        /// <summary>An IcoSphere</summary>
        /// <param name="radius">Radius of Sphere</param>
        /// <param name="SubDivisions">Number of times to divide base Icosahedron</param>
        public IcoSpherePrimitive(float radius, int SubDivisions) : base()
        {
            for (int i = 0; i < SubDivisions; i++) Subdivide(vertices, indices, true);

            //project each point onto sphere
            for (int i = 0; i < vertices.Count; i++)
            {
                float m = vertices[i].Length();
                Vector3 v = vertices[i];

                v.X *= radius / m;
                v.Y *= radius / m;
                v.Z *= radius / m;

                vertices[i] = v;
            }
        }
    }
}
