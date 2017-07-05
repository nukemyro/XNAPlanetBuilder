using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace XNACube
{
    public interface ICameraService
    {
        BoundingFrustum Frustum
        { get; }

        Viewport Viewport
        { get; }

        Matrix View
        { get; set; }

        Matrix Projection
        { get; }

        Vector3 Position
        { get; set; }

        Quaternion Rotation
        { get; set; }

        Matrix World
        { get; }

        Vector3 GetIntPosition();

        void Dispose();
    }
}
