using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace XNACube
{
    public class ClipMapLayer
    {
        public Vector3 Position;
        protected Effect Effect;
        Block[] Blocks = new Block[2];
        List<Trim> Trim = new List<Trim>(4);
        List<Fixup> Fixup = new List<Fixup>(2);
        public ClipMapLayer(int n, ContentManager cm, Game1 g)
        {
            LoadContent(cm);

            int m = (n + 1) / 4;
            int edge = (n / 8) - 1;

            for (int i = 0; i < Blocks.Length; i++)
            {
                Blocks[i] = new Block(m, cm, g);
                switch (i)
                {
                    case 0:
                        Blocks[i].Position = new Vector3(-edge, -edge, 0);
                        Blocks[i].BlockType = BlockTypes.TopLeft;
                        break;
                    case 1:
                        Blocks[i].Position = new Vector3(-edge/4, 1, 0);
                        Blocks[i].BlockType = BlockTypes.TopL;
                        break;
                        //case 2:
                        //    Blocks[i].Position = new Vector3(1, -edge, 0);
                        //    Blocks[i].BlockType = BlockTypes.TopR;
                        //    break;
                        //case 3:
                        //    Blocks[i].Position = new Vector3(m, -edge, 0);
                        //    Blocks[i].BlockType = BlockTypes.TopRight;
                        //    break;
                        //case 4:
                        //    Blocks[i].Position = new Vector3(-edge, -m, 0);
                        //    Blocks[i].BlockType = BlockTypes.Left;
                        //    break;
                        //case 5:
                        //    Blocks[i].Position = new Vector3(m, -m, 0);
                        //    Blocks[i].BlockType = BlockTypes.Right;
                        //    break;
                        //case 6:
                        //    Blocks[i].Position = new Vector3(-edge, 1, 0);
                        //    Blocks[i].BlockType = BlockTypes.Left;
                        //    break;
                        //case 7:
                        //    Blocks[i].Position = new Vector3(m, 1, 0);
                        //    Blocks[i].BlockType = BlockTypes.Right;
                        //    break;
                        //case 8:
                        //    Blocks[i].Position = new Vector3(-edge, m, 0);
                        //    Blocks[i].BlockType = BlockTypes.BottomLeft;
                        //    break;
                        //case 9:
                        //    Blocks[i].Position = new Vector3(-m, m, 0);
                        //    Blocks[i].BlockType = BlockTypes.BottomL;
                        //    break;
                        //case 10:
                        //    Blocks[i].Position = new Vector3(1, m, 0);
                        //    Blocks[i].BlockType = BlockTypes.BottomR;
                        //    break;
                        //case 11:
                        //    Blocks[i].Position = new Vector3(m, m, 0);
                        //    Blocks[i].BlockType = BlockTypes.BottomRight;
                        //    break;
                }
            }
        }   
        
        public void LoadContent(ContentManager cm)
        {
            Effect = cm.Load<Effect>("ClipMapTest");
        }
        public void Update(GameTime gameTime)
        {
            foreach (Block b in Blocks)
                b.Update(gameTime);
        }     

        public void Draw(Matrix View, Matrix Projection)
        {
            foreach (Block b in Blocks)
                b.Draw(View, Projection);
        }
    }
}
