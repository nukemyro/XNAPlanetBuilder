using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace XNACube
{
    public class PlanePrimitive : GeometricPrimitive
    {
        public int width, height;
        
        public PlanePrimitive(int w, int h) : base()
        {
            width = w;
            height = h;

            CreateVertices();
            CreateIndices();

            //Subdivide(vertices, indices, true);
        }

        void CreateVertices()
        {
            Vector3[] verts = new Vector3[width * height];

            vertices = new List<Vector3>(width * height);
            for (int x = 0; x < width; x++)            
                for (int y = 0; y < height; y++)
                    verts[x + y * width] = new Vector3(x, y, 0); //div by factor to make spaces smaller

            foreach (Vector3 v in verts)
                vertices.Add(v);
        }

        void CreateIndices()
        {
            //source : https://msdn.microsoft.com/en-us/library/bb196414.aspx#ID4E5H
            //drawing a triangle list
            indices = new List<int>((width - 1) * (height - 1) * 6);
            short[] inds = new short[(width - 1) * (height - 1) * 6];
            for (short x = 0; x < width - 1; x++)
            {
                for (short y = 0; y < height - 1; y++)
                {
                    inds[(x + y * (width - 1)) * 6] = (short)((x + 1) + (y + 1) * width);
                    inds[(x + y * (width - 1)) * 6 + 1] = (short)((x + 1) + y * width);
                    inds[(x + y * (width - 1)) * 6 + 2] = (short)(x + y * width);

                    inds[(x + y * (width - 1)) * 6 + 3] = (short)((x + 1) + (y + 1) * width);
                    inds[(x + y * (width - 1)) * 6 + 4] = (short)(x + y * width);
                    inds[(x + y * (width - 1)) * 6 + 5] = (short)(x + (y + 1) * width);
                }
            }

            foreach (int i in inds)
                indices.Add(i);
        }
    }
}
