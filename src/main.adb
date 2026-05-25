--  Task 1: Code Understanding
--------------------------------------------------------------------------------
--  Question 1
--
--  By using the distinct types "Position" and "Velocity" for calculations
--  instead of Vector, it prevents silent errors where incorrect data is
--  utilized due to the format of the data being identical. For example, when
--  using the procedure "Add_Item" to add bodies to the universe, if "pos" and
--  "vel" were declared as type "Vector.Vector", it would be possible to
--  mistakenly assign "pos" to the velocity vector and "vel" to the position
--  vector.
--
--  Additionally, it provides further clarity to the meaning of the data
--  returned by each function.
--
--------------------------------------------------------------------------------
--  Question 2
--
--  Pre => Index >= 1 and then Index <= Item_Count (U)
--  Ensures the index is within the bounds of the number of items in the
--  universe
--
--  Pre  => Item_Count (U) < Max_Items;
--  Ensures the number of items in the universe does not exceed the max number
--  of items
--
--------------------------------------------------------------------------------
--  Task 7: Reflection
--
--  Our proof shows that if the simulation continues past the collision check,
--  then the two objects are safely separated on the current frame. In other
--  words, the proof establishes safety for every frame that is actually shown:
--  Squared_Dist (U, 1, 2) is greater than Pair_Sep2 (1, 2). However, it does
--  not prove that every early stop means a collision would definitely have
--  happened if the simulation kept running. The collision check looks at the
--  current straight-line trajectories after the most recent bounce. It is
--  possible that a later wall bounce might change one object's velocity before
--  the two objects actually reach each other. So the check is conservative:
--  it may stop early to stay safe. In other words, some warnings may be false
--  alarms. 

with Universe;
with Spatial;
with Vector;                             use Vector;
with Collision_Math;
with Display;
with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Reals;
use Ada.Numerics.Big_Numbers.Big_Reals;

procedure Main with SPARK_Mode is
   use type Spatial.Position;
   use type Spatial.Velocity;
   package Univ is new Universe (10);

   package FC is new Float_Conversions (Float);
   package Disp is new Display (Univ, Max_Frames => 5500);

   U : Univ.Universe;

   Arena_X_Min : constant Big_Real := FC.To_Big_Real (-100.0);
   Arena_X_Max : constant Big_Real := FC.To_Big_Real (100.0);
   Arena_Y_Min : constant Big_Real := FC.To_Big_Real (-50.0);
   Arena_Y_Max : constant Big_Real := FC.To_Big_Real (50.0);

   Initial_Positions : array (1 .. 2) of Spatial.Position :=
     (Spatial.To_Position
        ((X => FC.To_Big_Real (0.0), Y => FC.To_Big_Real (5.0))),
      Spatial.To_Position
        ((X => FC.To_Big_Real (0.0), Y => FC.To_Big_Real (-5.0))));

   Initial_Velocities : array (1 .. 2) of Spatial.Velocity :=
     (Spatial.To_Velocity
        ((X => FC.To_Big_Real (0.4), Y => FC.To_Big_Real (0.3))),
      Spatial.To_Velocity
        ((X => FC.To_Big_Real (1.0), Y => FC.To_Big_Real (-0.7))));

   Initial_Radii : constant array (1 .. 2) of Big_Real :=
     (FC.To_Big_Real (2.0), FC.To_Big_Real (2.0));

   Tick_Count : Big_Real := To_Big_Real (0);

   --  Lets the proof talk about the universe at a specific tick value, 
   --  and Lemma_Advance_Position supplies the small algebra step needed 
   --  to prove that the invariant is preserved after each Tick. 
   --  This also gives Task 6 the Position_Invariant fact it needs
   --  before calling Lemma_No_Collision_Pair.
   function Position_At_Tick
     (U : Univ.Universe; T : Big_Real) return Boolean
   is (Univ.Item_Count (U) = 2
       and then T >= 0.0
       and then
         (for all I in 1 .. 2 =>
            Spatial.To_Vector (Univ.Get_Position (U, I))
            = Vector.Add
                (Spatial.To_Vector (Initial_Positions (I)),
                 Vector.Scale
                   (Spatial.Vel_To_Vector (Initial_Velocities (I)),
                    T))
            and then Univ.Get_Velocity (U, I) = Initial_Velocities (I)
            and then Univ.Get_Radius (U, I) = Initial_Radii (I)));

   function Position_Invariant (U : Univ.Universe) return Boolean
   is (Position_At_Tick (U, Tick_Count));

   --  Task 4: this ghost lemma proves the one-step movement algebra:
   --  initial + velocity * T, moved once more by velocity, equals
   --  initial + velocity * (T + 1).
   procedure Lemma_Advance_Position
     (Init : Spatial.Position; Vel : Spatial.Velocity; T : Big_Real)
   with
     Ghost,
     Pre  => T >= To_Big_Real (0),
     Post =>
       Spatial.To_Vector
         (Spatial.Move
            (Spatial.To_Position
               (Vector.Add
                  (Spatial.To_Vector (Init),
                   Vector.Scale (Spatial.Vel_To_Vector (Vel), T))),
             Vel))
       = Vector.Add
           (Spatial.To_Vector (Init),
            Vector.Scale
              (Spatial.Vel_To_Vector (Vel), T + To_Big_Real (1)));

   procedure Lemma_Advance_Position
     (Init : Spatial.Position; Vel : Spatial.Velocity; T : Big_Real)
   is
      Init_V : constant Vector.Vector := Spatial.To_Vector (Init);
      Vel_V  : constant Vector.Vector := Spatial.Vel_To_Vector (Vel);
   begin
      pragma Assert
        (Vel_V.X * T + Vel_V.X = Vel_V.X * (T + To_Big_Real (1)));
      pragma Assert
        (Vel_V.Y * T + Vel_V.Y = Vel_V.Y * (T + To_Big_Real (1)));
      pragma Assert
        (Init_V.X + Vel_V.X * T + Vel_V.X
         = Init_V.X + Vel_V.X * (T + To_Big_Real (1)));
      pragma Assert
        (Init_V.Y + Vel_V.Y * T + Vel_V.Y
         = Init_V.Y + Vel_V.Y * (T + To_Big_Real (1)));
   end Lemma_Advance_Position;

   function Squared_Dist (U : Univ.Universe; I, J : Integer) return Big_Real
   is (Vector.Dot
         (Vector.Sub
            (Spatial.To_Vector (Univ.Get_Position (U, I)),
             Spatial.To_Vector (Univ.Get_Position (U, J))),
          Vector.Sub
            (Spatial.To_Vector (Univ.Get_Position (U, I)),
             Spatial.To_Vector (Univ.Get_Position (U, J)))))
   with
     Pre =>
       I >= 1
       and then I <= Univ.Item_Count (U)
       and then J >= 1
       and then J <= Univ.Item_Count (U);

   function Pair_Sep2 (I, J : Integer) return Big_Real
   is ((Initial_Radii (I) + Initial_Radii (J))
       * (Initial_Radii (I) + Initial_Radii (J)))
   with Pre => I in 1 .. 2 and then J in 1 .. 2;

   --  Task 5: ask Collision_Math whether the current straight-line
   --  trajectories will ever collide. It needs the difference between the two
   --  positions, the difference between the two velocities, and the squared
   --  collision threshold.
   function No_Future_Collision_Pair (I, J : Integer) return Boolean
   is (not Collision_Math.Will_Collide_Vec
             (Vector.Sub
                (Spatial.To_Vector (Initial_Positions (I)),
                 Spatial.To_Vector (Initial_Positions (J))),
              Vector.Sub
                (Spatial.Vel_To_Vector (Initial_Velocities (I)),
                 Spatial.Vel_To_Vector (Initial_Velocities (J))),
              Pair_Sep2 (I, J)))
   with Pre => I in 1 .. 2 and then J in 1 .. 2;

   --  Task 6: connect the future-collision check to the current frame. If
   --  Collision_Math says there is no future collision and the position
   --  invariant describes the current universe, then the two objects are
   --  separated right now.
   procedure Lemma_No_Collision_Pair
     (U : Univ.Universe; I, J : Integer)
   with
     Ghost,
     Pre  =>
       Position_Invariant (U)
       and then I in 1 .. 2
       and then J in 1 .. 2
       and then Tick_Count >= To_Big_Real (0)
       and then No_Future_Collision_Pair (I, J),
     Post => Squared_Dist (U, I, J) > Pair_Sep2 (I, J);

   procedure Lemma_No_Collision_Pair
     (U : Univ.Universe; I, J : Integer)
   is
      P1 : constant Vector.Vector :=
        Spatial.To_Vector (Univ.Get_Position (U, I));
      P2 : constant Vector.Vector :=
        Spatial.To_Vector (Univ.Get_Position (U, J));
      Init1 : constant Vector.Vector :=
        Spatial.To_Vector (Initial_Positions (I));
      Init2 : constant Vector.Vector :=
        Spatial.To_Vector (Initial_Positions (J));
      Vel1 : constant Vector.Vector :=
        Spatial.Vel_To_Vector (Initial_Velocities (I));
      Vel2 : constant Vector.Vector :=
        Spatial.Vel_To_Vector (Initial_Velocities (J));
      S : constant Vector.Vector := Vector.Sub (Init1, Init2);
      V : constant Vector.Vector := Vector.Sub (Vel1, Vel2);
   begin
      Collision_Math.Lemma_Sq_Dist_Bridge
        (P1, P2, Init1, Init2, Vel1, Vel2, Tick_Count);
      Collision_Math.Check_Implies_Safe_Vec
        (S, V, Pair_Sep2 (I, J), Tick_Count);
   end Lemma_No_Collision_Pair;

   type Bounce_Flags is record
      X : Boolean := False;
      Y : Boolean := False;
   end record;

   type Bounce_Array is array (1 .. 2) of Bounce_Flags;

   function Detect_Bounces (U : Univ.Universe) return Bounce_Array
   with Pre => Univ.Item_Count (U) = 2;

   function Detect_Bounces (U : Univ.Universe) return Bounce_Array is
      Result : Bounce_Array := (others => (X => False, Y => False));
   begin
      for Item in 1 .. 2 loop
         declare
            P : constant Spatial.Position := Univ.Get_Position (U, Item);
            R : constant Big_Real := Univ.Get_Radius (U, Item);
         begin
            if Spatial.Pos_X (P) + R > Arena_X_Max
              or else Spatial.Pos_X (P) - R < Arena_X_Min
            then
               Result (Item).X := True;
            end if;
            if Spatial.Pos_Y (P) + R > Arena_Y_Max
              or else Spatial.Pos_Y (P) - R < Arena_Y_Min
            then
               Result (Item).Y := True;
            end if;
         end;
      end loop;
      return Result;
   end Detect_Bounces;

   procedure Print_Collision (Frame : Integer);

   procedure Print_Collision (Frame : Integer) with SPARK_Mode => Off is
   begin
      Ada.Text_IO.Put_Line
        ("Collision will occur after bounce at frame" & Integer'Image (Frame));
      for Item in 1 .. 2 loop
         declare
            V : constant Vector.Vector :=
              Spatial.Vel_To_Vector (Initial_Velocities (Item));
            P : constant Spatial.Position := Initial_Positions (Item);
         begin
            Ada.Text_IO.Put_Line
              ("  Item"
               & Integer'Image (Item)
               & " pos=("
               & To_String (Spatial.Pos_X (P))
               & ", "
               & To_String (Spatial.Pos_Y (P))
               & ")"
               & " vel=("
               & To_String (V.X)
               & ", "
               & To_String (V.Y)
               & ")");
         end;
      end loop;
      Ada.Text_IO.Put_Line ("  Sep2=" & To_String (Pair_Sep2 (1, 2)));
   end Print_Collision;

   --  Task 4: after a bounce, the initial positions/velocities are updated
   --  before reset. Rebuild U from those values and set Tick_Count to zero,
   --  re-establishing Position_Invariant.
   procedure Reset_Universe
   with Post => Position_Invariant (U)
   is
   begin
      Tick_Count := To_Big_Real (0);
      Univ.Init (U);
      Univ.Add_Item
        (U, Initial_Positions (1), Initial_Velocities (1), Initial_Radii (1));
      Univ.Add_Item
        (U, Initial_Positions (2), Initial_Velocities (2), Initial_Radii (2));
   end Reset_Universe;

begin
   Reset_Universe;

   --  Task 5: pre-loop collision check.
   if not No_Future_Collision_Pair (1, 2) then
      Print_Collision (0);
      return;
   end if;

   for Frame in 1 .. 5000 loop
      --  Task 4: the loop always starts with U matching the current
      --  Initial_Positions, Initial_Velocities, and Tick_Count.
      pragma Loop_Invariant (Position_Invariant (U));
      --  Task 5: preserve the no-future-collision check.
      pragma Loop_Invariant (No_Future_Collision_Pair (1, 2));

      --  Task 6: prove collision freedom on the current frame.
      Lemma_No_Collision_Pair (U, 1, 2);
      pragma Assert (Squared_Dist (U, 1, 2) > Pair_Sep2 (1, 2));

      Disp.Capture (U);
      --  Task 4: keep a ghost copy of the old state so the prover can compare
      --  positions before and after Tick.
      declare
         Old_Tick : constant Big_Real := Tick_Count with Ghost;
         Old_U    : constant Univ.Universe := U with Ghost;
      begin
         Univ.Tick (U);
         Tick_Count := Tick_Count + To_Big_Real (1);
         pragma Assert (Tick_Count = Old_Tick + To_Big_Real (1));

         for Item in 1 .. 2 loop
            pragma Loop_Invariant
              (Tick_Count = Old_Tick + To_Big_Real (1));
            pragma Loop_Invariant (Position_At_Tick (Old_U, Old_Tick));
            Lemma_Advance_Position
              (Initial_Positions (Item), Initial_Velocities (Item),
               Old_Tick);
            pragma Assert
              (Spatial.To_Vector (Univ.Get_Position (Old_U, Item))
               = Vector.Add
                   (Spatial.To_Vector (Initial_Positions (Item)),
                    Vector.Scale
                      (Spatial.Vel_To_Vector (Initial_Velocities (Item)),
                       Old_Tick)));
            pragma Assert
              (Univ.Get_Position (U, Item)
               = Spatial.Move
                   (Univ.Get_Position (Old_U, Item),
                    Univ.Get_Velocity (Old_U, Item)));
            pragma Assert
              (Spatial.To_Vector (Univ.Get_Position (U, Item))
               = Vector.Add
                   (Spatial.To_Vector (Initial_Positions (Item)),
                    Vector.Scale
                      (Spatial.Vel_To_Vector (Initial_Velocities (Item)),
                       Tick_Count)));
         end loop;
      end;

      declare
         Flags : constant Bounce_Array := Detect_Bounces (U);
      begin
         if Flags (1).X
           or else Flags (1).Y
           or else Flags (2).X
           or else Flags (2).Y
         then
            for Item in 1 .. 2 loop
               pragma Loop_Invariant (Univ.Item_Count (U) = 2);
               if Flags (Item).X then
                  Univ.Reflect_Velocity_X (U, Item);
               end if;
               if Flags (Item).Y then
                  Univ.Reflect_Velocity_Y (U, Item);
               end if;
            end loop;
            Initial_Positions :=
              (Univ.Get_Position (U, 1), Univ.Get_Position (U, 2));
            Initial_Velocities :=
              (Univ.Get_Velocity (U, 1), Univ.Get_Velocity (U, 2));

            Reset_Universe;

            --  Task 5: post-bounce collision check.
            if not No_Future_Collision_Pair (1, 2) then
               Print_Collision (Frame);
               exit;
            end if;

         end if;
      end;
   end loop;

   Disp.Capture (U);
   Disp.Save
     ("simulation.html", Arena_X_Min, Arena_X_Max, Arena_Y_Min, Arena_Y_Max);
   Ada.Text_IO.Put_Line ("Wrote simulation.html");
end Main;
