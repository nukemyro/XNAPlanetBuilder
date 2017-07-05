using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace XNACube
{
    public class ClipMap
    {
        ClipMapLayer[] Layers = new ClipMapLayer[1];
        string TerrainMap;
        Vector3 Position;
        Matrix World = Matrix.Identity;
        ICameraService Camera;        

        Block Center;

        public ClipMap(int n, string terrain, ContentManager cm, Game1 g)
        {                        
            Position = Vector3.Zero;
            Camera = ((ICameraService)g.Services.GetService(typeof(ICameraService)));

            ClipMapLayer l = new ClipMapLayer(n, cm, g);
            Layers[0] = l;            

            Center = new BlockCenter(n, cm, g);
        }

        public void Draw(Matrix View, Matrix Projection)
        {
            foreach (ClipMapLayer l in Layers)
                l.Draw(View, Projection);

            Center.Draw(View, Projection);
        }
        public void Update(GameTime gameTime)
        {            
            Position.X = Camera.Position.X;
            Position.Y = Camera.Position.Y;

            World = Matrix.CreateTranslation(Position);

            /* update layers */
            foreach (ClipMapLayer l in Layers)
            {                
                l.Update(gameTime);
            }

            //update this last
            //Center.Position = 
            Center.Update(gameTime);
        }
    }
    
}
