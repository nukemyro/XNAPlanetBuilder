using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace XNACube
{
    public class TreeVertexCollection
    {
        public VertexPositionNormalTexture[] Vertices;
        Vector3 _position;
        int _topSize;
        int _halfSize;
        int _vertexCount;
        int _scale;
        public VertexPositionNormalTexture this[int index]
        {
            get { return Vertices[index]; }
            set { Vertices[index] = value; }
        }


        public TreeVertexCollection(Vector3 position, Texture2D heightMap, int scale)
        {
        }
    }
}
