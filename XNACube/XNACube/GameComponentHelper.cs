using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace XNACube
{
    public static class GameComponentHelper
    {
        /// <summary>
        /// Plane used for cliping the view port for water reflections.
        /// </summary>
        public static Plane WaterReflectionPane;

        public static bool CreateWaterReflectionMap { get; set; }

        public static RenderTarget2D reflectionMap { get; set; }
        public static RenderTarget2D reflectionSGRMap { get; set; }
        public static RenderTarget2D lightMap { get; set; }

        /// <summary>
        /// Method to turn a 3D object to face a position in world space.
        /// </summary>
        /// <param name="target"></param>
        /// <param name="speed"></param>
        /// <param name="position"></param>
        /// <param name="rotation"></param>
        public static void LookAt(Vector3 target, float speed, Vector3 position, Quaternion rotation, Vector3 fwd)
        {
            LookAt(target, speed, position, ref rotation, fwd);
        }
        public static void LookAt(Vector3 target, float speed, Vector3 position, ref Quaternion rotation, Vector3 fwd)
        {
            if (fwd == Vector3.Zero)
                fwd = Vector3.Forward;

            Vector3 tminusp = target - position;
            Vector3 ominusp = fwd;

            if (tminusp == Vector3.Zero)
                return;

            tminusp.Normalize();

            float theta = (float)System.Math.Acos(Vector3.Dot(tminusp, ominusp));
            Vector3 cross = Vector3.Cross(ominusp, tminusp);

            if (cross == Vector3.Zero)
                return;

            cross.Normalize();

            Quaternion targetQ = Quaternion.CreateFromAxisAngle(cross, theta);
            rotation = Quaternion.Slerp(rotation, targetQ, speed);
        }

        public static void LookAtLockRotation(Vector3 target, float speed, Vector3 position, ref Quaternion rotation, Vector3 fwd, Vector3 lockedRots)
        {
            LookAt(target, speed, position, ref rotation, fwd);

            LockRotation(ref rotation, lockedRots);

        }

        public static void LockRotation(ref Quaternion rotation, Vector3 lockedRots)
        {
            lockedRots -= -Vector3.One;
            Vector3 rots = GameComponentHelper.QuaternionToEulerAngleVector3(rotation) * lockedRots;
            rotation = Quaternion.CreateFromRotationMatrix(Matrix.CreateRotationX(rots.X) * Matrix.CreateRotationY(rots.Y) * Matrix.CreateRotationX(rots.Z));
        }

        /// <summary>
        /// Method to rotate an object.
        /// </summary>
        /// <param name="axis"></param>
        /// <param name="angle"></param>
        /// <param name="rotation"></param>
        public static void Rotate(Vector3 axis, float angle, ref Quaternion rotation)
        {
            axis = Vector3.Transform(axis, Matrix.CreateFromQuaternion(rotation));
            rotation = Quaternion.Normalize(Quaternion.CreateFromAxisAngle(axis, angle) * rotation);
        }
        public static void RotateAA(Vector3 axis, float angle, ref Quaternion rotation)
        {
            //axis = Vector3.Transform(axis, Matrix.CreateFromQuaternion(rotation));
            rotation = Quaternion.Normalize(Quaternion.CreateFromAxisAngle(axis, angle) * rotation);
        }
        /// <summary>
        /// Method to translate a 3D object based on it's rotation
        /// </summary>
        /// <param name="distance"></param>
        /// <param name="rotation"></param>
        /// <returns></returns>
        public static Vector3 Translate3D(Vector3 distance, Quaternion rotation)
        {
            return Vector3.Transform(distance, Matrix.CreateFromQuaternion(rotation));
        }
        /// <summary>
        /// Method to translate a 3D object
        /// </summary>
        /// <param name="distance"></param>
        /// <returns></returns>
        public static Vector3 Translate3D(Vector3 distance)
        {
            return Vector3.Transform(distance, Matrix.CreateFromQuaternion(Quaternion.Identity));
        }
        /// <summary>
        /// Method to revolve and object
        /// </summary>
        /// <param name="target"></param>
        /// <param name="axis"></param>
        /// <param name="angle"></param>
        /// <param name="position"></param>
        /// <param name="rotation"></param>
        public static void Revolve(Vector3 target, Vector3 axis, float angle, ref Vector3 position, ref Quaternion rotation)
        {
            GameComponentHelper.Rotate(axis, angle, ref rotation);
            Vector3 revolveAxis = Vector3.Transform(axis, Matrix.CreateFromQuaternion(rotation));
            Quaternion rotate = Quaternion.CreateFromAxisAngle(revolveAxis, angle);
            position = Vector3.Transform(target - position, Matrix.CreateFromQuaternion(rotate));
        }

        // Converts a Quaternion to Euler angles (X = Yaw, Y = Pitch, Z = Roll)
        public static Vector3 QuaternionToEulerAngleVector3(Quaternion rotation)
        {
            Vector3 rotationaxes = new Vector3();
            Vector3 forward = Vector3.Transform(Vector3.Forward, rotation);
            Vector3 up = Vector3.Transform(Vector3.Up, rotation);

            rotationaxes = AngleTo(new Vector3(), forward);

            if (rotationaxes.X == MathHelper.PiOver2)
            {
                rotationaxes.Y = (float)Math.Atan2((double)up.X, (double)up.Z);
                rotationaxes.Z = 0;
            }
            else if (rotationaxes.X == -MathHelper.PiOver2)
            {
                rotationaxes.Y = (float)Math.Atan2((double)-up.X, (double)-up.Z);
                rotationaxes.Z = 0;
            }
            else
            {
                up = Vector3.Transform(up, Matrix.CreateRotationY(-rotationaxes.Y));
                up = Vector3.Transform(up, Matrix.CreateRotationX(-rotationaxes.X));

                //rotationaxes.Z = (float)Math.Atan2((double)-up.Z, (double)up.Y);
                rotationaxes.Z = (float)Math.Atan2((double)-up.X, (double)up.Y);
            }

            return rotationaxes;
        }


        // Returns Euler angles that point from one point to another
        public static Vector3 AngleTo(Vector3 from, Vector3 location)
        {
            Vector3 angle = new Vector3();
            Vector3 v3 = Vector3.Normalize(location - from);

            angle.X = (float)Math.Asin(v3.Y);
            angle.Y = (float)Math.Atan2((double)-v3.X, (double)-v3.Z);

            return angle;
        }

        /// <summary>
        /// Method to get a 3D objects 2D scren coords.
        /// </summary>
        /// <param name="myPosition"></param>
        /// <param name="Camera"></param>
        /// <returns></returns>
        public static Vector2 Get2DCoords(Vector3 myPosition, ICameraService Camera)
        {
            Matrix ViewProjectionMatrix = Camera.View * Camera.Projection;

            Vector4 result4 = Vector4.Transform(myPosition, ViewProjectionMatrix);

            if (result4.W <= 0)
                return new Vector2(Camera.Viewport.Width, 0);

            Vector3 result = new Vector3(result4.X / result4.W, result4.Y / result4.W, result4.Z / result4.W);

            Vector2 retVal = new Vector2((int)Math.Round(+result.X * (Camera.Viewport.Width / 2)) + (Camera.Viewport.Width / 2), (int)Math.Round(-result.Y * (Camera.Viewport.Height / 2)) + (Camera.Viewport.Height / 2));
            return retVal;
        }

        /// <summary>
        /// Method to get screens tex coords.
        /// </summary>
        /// <param name="worldPosition"></param>
        /// <param name="Camera"></param>
        /// <returns></returns>
        public static Vector2 GetScreenTexCoords(Vector3 worldPosition, ICameraService Camera)
        {
            Vector2 retVal;

            retVal = Get2DCoords(worldPosition, Camera);

            retVal.X /= Camera.Viewport.Width;
            retVal.Y /= Camera.Viewport.Height;

            return retVal;
        }

        public static Ray BuildRay(Point screenPixel, ICameraService camera)
        {
            Vector3 nearSource = camera.Viewport.Unproject(new Vector3(screenPixel.X, screenPixel.Y, camera.Viewport.MinDepth), camera.Projection, camera.View, Matrix.Identity);
            Vector3 farSource = camera.Viewport.Unproject(new Vector3(screenPixel.X, screenPixel.Y, camera.Viewport.MaxDepth), camera.Projection, camera.View, Matrix.Identity);
            Vector3 direction = farSource - nearSource;

            direction.Normalize();

            return new Ray(nearSource, direction);
        }

        public static float RayPicking(Point screenPixel, BoundingSphere volume, ICameraService camera)
        {
            Nullable<float> retVal = float.MaxValue;

            BuildRay(screenPixel, camera).Intersects(ref volume, out retVal);

            if (retVal != null)
                return retVal.Value;
            else
                return float.MaxValue;
        }

        public static float RayPicking(Point screenPixel, BoundingBox volume, ICameraService camera)
        {
            Nullable<float> retVal = float.MaxValue;

            BuildRay(screenPixel, camera).Intersects(ref volume, out retVal);

            if (retVal != null)
                return retVal.Value;
            else
                return float.MaxValue;
        }

        public static float TurnToFace(Vector2 position, Vector2 faceThis,
            float currentAngle, float turnSpeed, float offset)
        {
            // consider this diagram:
            //         C 
            //        /|
            //      /  |
            //    /    | y
            //  / o    |
            // S--------
            //     x
            // 
            // where S is the position of the spot light, C is the position of the cat,
            // and "o" is the angle that the spot light should be facing in order to 
            // point at the cat. we need to know what o is. using trig, we know that
            //      tan(theta)       = opposite / adjacent
            //      tan(o)           = y / x
            // if we take the arctan of both sides of this equation...
            //      arctan( tan(o) ) = arctan( y / x )
            //      o                = arctan( y / x )
            // so, we can use x and y to find o, our "desiredAngle."
            // x and y are just the differences in position between the two objects.
            float x = faceThis.X - position.X;
            float y = faceThis.Y - position.Y;

            // we'll use the Atan2 function. Atan will calculates the arc tangent of 
            // y / x for us, and has the added benefit that it will use the signs of x
            // and y to determine what cartesian quadrant to put the result in.
            // http://msdn2.microsoft.com/en-us/library/system.math.atan2.aspx
            float desiredAngle = (float)Math.Atan2(y, x) + offset;

            // so now we know where we WANT to be facing, and where we ARE facing...
            // if we weren't constrained by turnSpeed, this would be easy: we'd just 
            // return desiredAngle.
            // instead, we have to calculate how much we WANT to turn, and then make
            // sure that's not more than turnSpeed.

            // first, figure out how much we want to turn, using WrapAngle to get our
            // result from -Pi to Pi ( -180 degrees to 180 degrees )
            float difference = WrapAngle(desiredAngle - currentAngle);

            // clamp that between -turnSpeed and turnSpeed.
            difference = MathHelper.Clamp(difference, -turnSpeed, turnSpeed);

            // so, the closest we can get to our target is currentAngle + difference.
            // return that, using WrapAngle again.
            return WrapAngle(currentAngle + difference);
        }

        public static float WrapAngle(float radians)
        {
            while (radians < -MathHelper.Pi)
            {
                radians += MathHelper.TwoPi;
            }
            while (radians > MathHelper.Pi)
            {
                radians -= MathHelper.TwoPi;
            }
            return radians;
        }

        public static void PrintMatrix(StringBuilder writer, Microsoft.Xna.Framework.Matrix m)
        {
            PrintMatrix(writer, null, m);
        }

        public static void PrintMatrix(StringBuilder writer, String name, Microsoft.Xna.Framework.Matrix m)
        {
            if (writer != null)
            {
                if (name != null)
                {
                    writer.AppendLine(name);
                }
                PrintVector3(writer, "Right       ", m.Right);
                PrintVector3(writer, "Up          ", m.Up);
                PrintVector3(writer, "Backward    ", m.Backward);
                PrintVector3(writer, "Translation ", m.Translation);
            }
        }


        public static void PrintVector3(StringBuilder writer, Microsoft.Xna.Framework.Vector3 v)
        {
            writer.AppendLine(String.Format("{{X:{0:0.00000000} Y:{1:0.00000000} Z:{2:0.00000000}}}", v.X, v.Y, v.Z));
        }

        public static void PrintVector3(StringBuilder writer, String name, Microsoft.Xna.Framework.Vector3 v)
        {
            writer.AppendLine(String.Format("[{0}] {{X:{1:0.00000000} Y:{2:0.00000000} Z:{3:0.00000000}}}", name, v.X, v.Y, v.Z));
        }

        public static Plane CreatePlane(float height, Vector3 planeNormalDirection, Matrix currentViewMatrix, bool clipSide, Matrix projectionMatrix)
        {
            planeNormalDirection.Normalize();
            Vector4 planeCoeffs = new Vector4(planeNormalDirection, height);
            if (clipSide)
                planeCoeffs *= -1;

            Matrix worldViewProjection = currentViewMatrix * projectionMatrix;
            Matrix inverseWorldViewProjection = Matrix.Invert(worldViewProjection);
            inverseWorldViewProjection = Matrix.Transpose(inverseWorldViewProjection);

            planeCoeffs = Vector4.Transform(planeCoeffs, inverseWorldViewProjection);
            Plane finalPlane = new Plane(planeCoeffs);

            return finalPlane;
        }

    }
}
