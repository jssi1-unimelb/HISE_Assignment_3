with Ada.Text_IO;
with Ada.Integer_Text_IO;
with Universe;

package body Universe
  with SPARK_Mode
is

   procedure Init (U : out Universe) is
      init_pos : Spatial.Position :=
        Spatial.To_Position ((X => 0.0, Y => 0.0));
      init_vel : Spatial.Velocity :=
        Spatial.To_Velocity ((X => 0.0, Y => 0.0));
      init_rad : Big_Real := 0.0;
   begin
      U.items :=
        (others => (pos => init_pos, vel => init_vel, rad => init_rad));
      U.item_count := 0;
   end Init;

   procedure Add_Item
     (U   : in out Universe;
      pos : Spatial.Position;
      vel : Spatial.Velocity;
      rad : Big_Real)
   is
      new_item : Universe_Item := (pos, vel, rad);
   begin
      U.Item_Count := U.Item_Count + 1;
      U.items (U.Item_Count) := new_item;
   end Add_Item;

   function Item_Was_Added
     (U   : Universe;
      pos : Spatial.Position;
      vel : Spatial.Velocity;
      rad : Big_Real) return Boolean
   is (U.items (U.Item_Count) = (pos => pos, vel => vel, rad => rad));

   procedure Reflect_Velocity_X (U : in out Universe; Index : Integer) is
   begin
      U.items (Index).vel := Spatial.Negate_Vel_X (Get_Velocity (U, Index));
   end Reflect_Velocity_X;

   procedure Reflect_Velocity_Y (U : in out Universe; Index : Integer) is
   begin
      U.items (Index).vel := Spatial.Negate_Vel_Y (Get_Velocity (U, Index));
   end Reflect_Velocity_Y;

   procedure Print (U : Universe) with SPARK_Mode => Off is
   begin
      for I in U.items'First .. U.item_count loop
         Ada.Text_IO.Put ("Item: ");
         Ada.Integer_Text_IO.Put (I);
         Ada.Text_IO.Put (": pos: (");
         Ada.Text_IO.Put (To_String (Spatial.Pos_X (U.items (I).pos)));
         Ada.Text_IO.Put (",");
         Ada.Text_IO.Put (To_String (Spatial.Pos_Y (U.items (I).pos)));
         Ada.Text_IO.Put (")");
         Ada.Text_IO.New_Line;
      end loop;
   end Print;

   procedure Tick (U : in out Universe) is
      U_Old : Universe := U
      with Ghost;
   begin
      for I in 1 .. U.item_count loop
         --  Task 3: processed items have moved; unprocessed items are still
         --  equal to the old universe. This proves Tick's postcondition.
         pragma Loop_Invariant (Item_Count (U) = Item_Count (U_Old)); -- T3
         pragma -- T3
           Loop_Invariant -- T3
             (for all J in 1 .. I - 1 => -- T3
                Get_Position (U, J) -- T3
                = Spatial.Move (Get_Position (U_Old, J), -- T3
                                Get_Velocity (U_Old, J)) -- T3
                and then Get_Velocity (U, J) = Get_Velocity (U_Old, J) -- T3
                and then Get_Radius (U, J) = Get_Radius (U_Old, J)); -- T3
         pragma -- T3
           Loop_Invariant -- T3
             (for all J in I .. Item_Count (U) => -- T3
                Get_Position (U, J) = Get_Position (U_Old, J) -- T3
                and then Get_Velocity (U, J) = Get_Velocity (U_Old, J) -- T3
                and then Get_Radius (U, J) = Get_Radius (U_Old, J)); -- T3

         U.items (I).pos := Spatial.Move (U.items (I).pos, U.items (I).vel);
      end loop;
   end Tick;
end Universe;
