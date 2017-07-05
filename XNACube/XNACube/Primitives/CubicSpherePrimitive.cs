
using Microsoft.Xna.Framework;

namespace XNACube
{
    public class CubicSpherePrimitive : CubePrimitive
    {
        public CubicSpherePrimitive(float radius, int divisions) : base (radius)
        {
            for(int i = 0; i < divisions; i++) Subdivide(vertices, indices, true);

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
