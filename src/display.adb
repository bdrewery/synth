--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with JohnnyText;

package body Display is

   package JT renames JohnnyText;

   ----------------------
   --  launch_monitor  --
   ----------------------
   function launch_monitor (num_builders : builders) return Boolean is
   begin
      TIC.Init_Screen;
      if not TIC.Has_Colors then
         TIC.End_Windows;
         return False;
      end if;
      TIC.Set_Echo_Mode (False);
      TIC.Set_Raw_Mode (True);
      TIC.Set_Cbreak_Mode (True);

      TIC.Start_Color;
      TIC.Init_Pair (TIC.Color_Pair (1), TIC.White,  TIC.Black);
      TIC.Init_Pair (TIC.Color_Pair (2), TIC.Green,  TIC.Black);
      TIC.Init_Pair (TIC.Color_Pair (3), TIC.Red,    TIC.Black);
      TIC.Init_Pair (TIC.Color_Pair (4), TIC.Yellow, TIC.Black);
      TIC.Init_Pair (TIC.Color_Pair (5), TIC.Black,  TIC.Black);
      TIC.Init_Pair (TIC.Color_Pair (6), TIC.Cyan,   TIC.Black);
      TIC.Init_Pair (TIC.Color_Pair (7), TIC.White,  TIC.Blue);

      c_standard    := TIC.Color_Pair (1);
      c_success     := TIC.Color_Pair (2);
      c_failure     := TIC.Color_Pair (3);
      c_ignored     := TIC.Color_Pair (4);
      c_skipped     := TIC.Color_Pair (5);
      c_sumlabel    := TIC.Color_Pair (6);
      c_builderbar  := TIC.Color_Pair (7);
      c_elapsed     := TIC.Color_Pair (4);

      launch_summary_zone;
      launch_builders_zone (num_builders);
      launch_actions_zone (num_builders);
      return True;
   end launch_monitor;


   -------------------------
   --  terminate_monitor  --
   -------------------------
   procedure terminate_monitor is
   begin
      TIC.Delete (Win => zone_actions);
      TIC.Delete (Win => zone_builders);
      TIC.Delete (Win => zone_summary);
      TIC.End_Windows;
   end terminate_monitor;


   ---------------------------
   --  launch_summary_zone  --
   ---------------------------
   procedure launch_summary_zone
   is
      line1 : String := "Total 0       Built 0      Ignored 0      " &
                        "Load  0.00  Pkg/hour 0   ";
      line2 : String := " Left 0      Failed 0      skipped 0      " &
                        "swap  0.0%   Impulse 0     00:00:00";
   begin
      zone_summary := TIC.Create (Number_Of_Lines       => 2,
                                  Number_Of_Columns     => app_width,
                                  First_Line_Position   => 0,
                                  First_Column_Position => 0);

      TIC.Set_Character_Attributes (Win   => zone_summary,
                                    Attr  => bright,
                                    Color => TIC.Color_Pair (c_sumlabel));

      TIC.Move_Cursor (Win => zone_summary, Line => 0, Column => 0);
      TIC.Add (Win => zone_summary, Str => line1);
      TIC.Move_Cursor (Win => zone_summary, Line => 1, Column => 0);
      TIC.Add (Win => zone_summary, Str => line2);

      TIC.Refresh (Win => zone_summary);
   end launch_summary_zone;


   ----------------------------
   --  launch_builders_zone  --
   ----------------------------
   procedure launch_builders_zone (num_builders : builders)
   is
      hghtint : constant Integer := 2 + Integer (num_builders);
      height  : constant TIC.Line_Position := TIC.Line_Position (hghtint);
   begin
      zone_builders := TIC.Create (Number_Of_Lines       => height,
                                   Number_Of_Columns     => app_width,
                                   First_Line_Position   => 2,
                                   First_Column_Position => 0);
   end launch_builders_zone;


   ---------------------------
   --  launch_actions_zone  --
   ---------------------------
   procedure launch_actions_zone (num_builders : builders)
   is
      consumed   : constant Integer := Integer (num_builders) + 2 + 2;
      difference : constant Integer := 0 - consumed;
      viewheight : constant TIC.Line_Position := inc (TIC.Lines, difference);
      viewpos    : constant TIC.Line_Position := TIC.Line_Position (consumed);
   begin
      zone_actions := TIC.Create (Number_Of_Lines       => viewheight,
                                  Number_Of_Columns     => app_width,
                                  First_Line_Position   => viewpos,
                                  First_Column_Position => 0);
   end launch_actions_zone;


   -----------
   --  inc  --
   -----------
   function inc (X : TIC.Line_Position; by : Integer) return TIC.Line_Position
   is
      use type TIC.Line_Position;
   begin
      return X + TIC.Line_Position (by);
   end inc;


   -----------------
   --  summarize  --
   -----------------
   procedure summarize (data : summary_rec)
   is
      function pad (S : String; amount : Positive := 5) return String;
      function fmtpc (f : Float; percent : Boolean) return String;
      procedure colorado (S : String; color :  TIC.Color_Pair;
                          col : TIC.Column_Position;
                          row : TIC.Line_Position;
                          dim : Boolean := False);

      remaining : constant Integer := data.Initially - data.Built -
        data.Failed - data.Ignored - data.Skipped;

      function pad (S : String; amount : Positive := 5) return String
      is
         result : String (1 .. amount) := (others => ' ');
         slen   : constant Natural := S'Length;
      begin
         result (1 .. slen) := S;
         return result;
      end pad;
      function fmtpc (f : Float; percent : Boolean) return String
      is
         type loadtype is delta 0.01 digits 3;
         result : String (1 .. 5) := (others => ' ');
         raw1   : constant loadtype := loadtype (f);
         raw2   : constant String := raw1'Img;
         rlen   : constant Natural := raw2'Length;
         start  : constant Natural := 6 - rlen;
      begin
         result (start .. 5) := raw2;
         if percent then
            result (5) := '%';
         end if;
         return result;
      end fmtpc;
      procedure colorado (S : String; color :  TIC.Color_Pair;
                          col : TIC.Column_Position;
                          row : TIC.Line_Position;
                          dim : Boolean := False) is
      begin
         if dim then
            TIC.Set_Character_Attributes (Win   => zone_summary,
                                          Attr  => TIC.Normal_Video,
                                          Color => color);
         else
            TIC.Set_Character_Attributes (Win   => zone_summary,
                                          Attr  => bright,
                                          Color => color);
         end if;
         TIC.Move_Cursor (Win => zone_summary, Line => row, Column => col);
         TIC.Add (Win => zone_summary, Str => S);
      end colorado;

      L1F1 : constant String := pad (JT.int2str (data.Initially));
      L1F2 : constant String := pad (JT.int2str (data.Built));
      L1F3 : constant String := pad (JT.int2str (data.Ignored));
      L1F4 : constant String := fmtpc (data.load, False);
      L1F5 : constant String := pad (JT.int2str (data.pkg_hour), 4);

      L2F1 : constant String := pad (JT.int2str (remaining));
      L2F2 : constant String := pad (JT.int2str (data.Failed));
      L2F3 : constant String := pad (JT.int2str (data.Skipped));
      L2F4 : constant String := fmtpc (data.swap, True);
      L2F5 : constant String := pad (JT.int2str (data.impulse), 4);

   begin

      colorado (L1F1, c_standard,  6, 0);
      colorado (L1F2, c_success,  20, 0);
      colorado (L1F3, c_ignored,  35, 0);
      colorado (L1F4, c_standard, 47, 0, True);
      colorado (L1F5, c_standard, 63, 0, True);

      colorado (L2F1, c_standard,  6, 1);
      colorado (L2F2, c_failure,  20, 1);
      colorado (L2F3, c_skipped,  35, 1);
      colorado (L2F4, c_standard, 47, 1, True);
      colorado (L2F5, c_standard, 63, 1, True);
      colorado (data.elapsed, c_elapsed, 69, 1);

      TIC.Refresh (Win => zone_summary);
   end summarize;


end Display;