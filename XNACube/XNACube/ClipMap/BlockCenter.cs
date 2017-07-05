using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace XNACube
{
    public class BlockCenter : Block
    {
        public BlockCenter(int n, ContentManager cm, Game1 g) : base(n, cm, g)
        {
            Position = new Vector3(-edge, -edge, 0);
            //Position = Vector3.Zero;
            //Position = new Vector3(-m / 4, -m / 4, 0);
            BlockType = BlockTypes.Center;         
        }

        public override void InitializeSize(int n)
        {
            m = n;
            edge = (n / 2) - 1;
        }
    }
}
