using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Content;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace XNACube
{
    public enum BlockTypes
    {
        Center,
        TopLeft,
        TopL,
        TopR,
        TopRight,
        Right,
        BottomRight,
        BottomL,
        BottomR,
        BottomLeft,
        Left
    }
    public class Block
    {
        public int m = 0;
        public int edge = 0;
        public BlockTypes BlockType;
        public Matrix World = Matrix.Identity;
        public PlanePrimitive block;
        public Vector3 Position;
        public Effect Effect;
        ContentManager Content;
        GraphicsDevice Device;
        ICameraService Camera;

        Vector3[] positions;
        //VertexPositionNormalTexture[] vertices;
        VertexPositionColor[] vertices;
        protected short[] indices;        
        
        public Block(int n, ContentManager cm, Game1 g)
        {            
            Content = cm;
            Device = g.GraphicsDevice;
            Camera = ((ICameraService)g.Services.GetService(typeof(ICameraService)));
                        
            Initialize(n);
            LoadContent();
        }

        public virtual void InitializeSize(int n)
        {
            m = (n + 1) / 4;
            edge = (n / 2) - 1;
        }

        public void Initialize(int n)
        {
            InitializeSize(n);

            block = new PlanePrimitive(m, m);

            positions = new Vector3[block.vertices.Count];
            //vertices = new VertexPositionNormalTexture[block.vertices.Count];
            vertices = new VertexPositionColor[block.vertices.Count];

            indices = new short[block.indices.Count];

            /* calculate uv texture mappings */
            for (int i = 0; i < vertices.Length; i++)
            {                                
                Vector3 norm = block.vertices[i];
                norm.Normalize();//normal vector
                Vector2 uv = MapUv(norm);//UV coordinates             

                //vertices[i].Position = block.vertices[i];                
                positions[i] = block.vertices[i];

                //vertices[i].Normal = norm;
                //vertices[i].TextureCoordinate = uv;
            }

            //copy over indices
            for (int i = 0; i < indices.Length; i++)
                indices[i] = (short)block.indices[i];
        }

        public void LoadContent()
        {
            Effect = Content.Load<Effect>("ClipMapTest");
        }

        public void Update(GameTime gameTime)
        {
            Vector3 CamPos = Vector3.Zero;
            CamPos.X = Camera.Position.X;
            CamPos.Y = Camera.Position.Y;

            Color c = Color.White;
            switch(BlockType)
            {
                case BlockTypes.Center:
                    break;
                case BlockTypes.TopLeft:
                    c = Color.Blue;
                    break;
                case BlockTypes.TopL:
                    c = Color.Red;                    
                    break;
            }

            World = Matrix.CreateTranslation(Position);

            for (int i = 0; i < positions.Length; i++)
            {
                vertices[i].Position = Vector3.Transform(positions[i], World);
                vertices[i].Color = c;
            }
        }

        public void Draw(Matrix View, Matrix Projection)
        {
            Effect.Parameters["World"].SetValue(World);
            Effect.Parameters["View"].SetValue(View);
            Effect.Parameters["Projection"].SetValue(Projection);
            Effect.CurrentTechnique = Effect.Techniques[0];
            Effect.CurrentTechnique.Passes[0].Apply();


            //Device.DrawUserIndexedPrimitives<VertexPositionNormalTexture>(
            Device.DrawUserIndexedPrimitives<VertexPositionColor>(
                PrimitiveType.TriangleList,
                vertices,
                0,
                vertices.Length,
                indices,
                0,
                (block.width - 1) * (block.height - 1) * 2);
        }

        private Vector2 MapUv(Vector3 p)
        {
            float u = 0.5f + ((float)Math.Atan2(p.Z, p.X) / MathHelper.TwoPi);
            float v = 0.5f - 2.0f * ((float)Math.Asin(p.Y) / MathHelper.TwoPi);

            return new Vector2(u, v);
        }

    }
}
