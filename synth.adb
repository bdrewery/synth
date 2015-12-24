--  This file is covered by the Internet Software Consortium (ISC) License
--  Reference: ../License.txt

with PortScan.Ops;
with PortScan.Packages;
with PortScan.Buildcycle;
with Parameters;
with Actions;
with Ada.Text_IO;
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Unbounded;

with Definitions;
with Replicant;

procedure synth
is
   pid : PortScan.port_id;
   good_scan : Boolean;
   pkg_good  : Boolean;
   --  repo : constant String := "/usr/local/boom/data/packages/dev-potential/All";

   package T   renames Ada.Text_IO;
   package OPS renames PortScan.Ops;
   use type PortScan.port_id;

   function USS (US : Ada.Strings.Unbounded.Unbounded_String) return String;
   function USS (US : Ada.Strings.Unbounded.Unbounded_String) return String is
   begin
      return Ada.Strings.Unbounded.To_String (US);
   end USS;
begin

   PortScan.set_cores;
   if not Parameters.load_configuration (num_cores => PortScan.cores_available)
   then
      return;
   end if;

   Actions.print_version;
   Actions.print_help;

   Replicant.initialize;
--     Replicant.launch_slave (3);
--     Replicant.launch_slave (12);
--     delay 35.0;
--     Replicant.destroy_slave (3);
--     Replicant.destroy_slave (12);
--   return;

   --  needs to read environment or make -C <anyport> -V PORTSDIR
--     good_scan := PortScan.scan_entire_ports_tree (portsdir => "/usr/xports");

   good_scan := PortScan.scan_single_port
     (portsdir => USS (Parameters.configuration.dir_portsdir),
      catport => "ports-mgmt/pkg",
      repository => USS (Parameters.configuration.dir_repository));

   if good_scan then
      PortScan.set_build_priority;
   else
      T.Put_Line ("pkg(8) scan failure, exiting");
      Replicant.finalize;
      return;
   end if;

   PortScan.Packages.limited_sanity_check
     (repository => USS (Parameters.configuration.dir_repository));

   if not PortScan.Packages.queue_is_empty then
      PortScan.Buildcycle.initialize (False);
      pid := PortScan.Ops.top_buildable_port;
      T.Put_Line ("Rebuilding pkg(8) First ...");

      Replicant.launch_slave (id => 1);
      pkg_good := PortScan.Buildcycle.build_package
        (id => 1, sequence_id => pid);
      Replicant.destroy_slave (id => 1);
      if not pkg_good then
         T.Put_Line ("Failed to build pkg(8), exiting");
         Replicant.finalize;
         return;
      end if;
   end if;

   PortScan.reset_ports_tree;

   good_scan := PortScan.scan_single_port
     (portsdir => USS (Parameters.configuration.dir_portsdir),
      catport => "editors/joe",
      repository => USS (Parameters.configuration.dir_repository));



--     good_scan := PortScan.scan_single_port
--       (portsdir => USS (Parameters.configuration.dir_portsdir),
--        catport => "mail/thunderbird",
--        repository => USS (Parameters.configuration.dir_repository));

   if good_scan then
      PortScan.set_build_priority;
   else
      Replicant.finalize;
      return;
   end if;


   PortScan.Packages.limited_sanity_check
     (repository => USS (Parameters.configuration.dir_repository));

   --  return;

   T.Put_Line ("");
   T.Put_Line ("Initial Queue length is" & OPS.queue_length'Img);
   loop
      pid := OPS.next_ignored_port;
      if pid = PortScan.port_match_failed then
         exit;
      end if;
      T.Put_Line (OPS.port_name (pid) & " has been ignored: " &
                  (OPS.ignore_reason (pid)));
      OPS.cascade_failed_build (pid);
--        declare
--           purged : PortScan.port_id;
--        begin
--           loop
--              purged := OPS.skip_next_reverse_dependency (pid);
--              exit when purged = OPS.port_match_failed;
--              if OPS.skip_verified (purged) then
--                 T.Put_Line ("   skipped: " & OPS.port_name (purged));
--              end if;
--           end loop;
--        end;
--        OPS.unlist_port (pid);
   end loop;
   T.Put_Line ("Final Queue length is" & OPS.queue_length'Img);
   if PortScan.Packages.queue_is_empty then
      T.Put_Line ("Everything is Ok, there's nothing to do.");
   else
      if OPS.integrity_intact then
         T.Put_Line ("Integrity intact");
      else
         T.Put_Line ("Integrity lost !!!!");
      end if;

      T.Put_Line ("Starting build simulation");
--     declare
--        type Rand_Draw is range 1 .. 100;
--        package Rand_Int is new Ada.Numerics.Discrete_Random (Rand_Draw);
--        seed : Rand_Int.Generator;
--     begin
--        Rand_Int.Reset (seed);
--        loop
--           declare
--              next_up : PortScan.port_id := OPS.top_buildable_port;
--              num : Rand_Draw := Rand_Int.Random (seed);
--           begin
--              exit when next_up = OPS.port_match_failed;
--
--              if False then -- num = 44 then
--                 T.Put_Line ("BOOOOOOOOOOM " & OPS.port_name (next_up));
--                 OPS.cascade_failed_build (next_up);
--              else
--                 T.Put_Line ("Built " & OPS.port_name (next_up));
--                 OPS.cascade_successful_build (id => next_up);
--              end if;
--           end;
--        end loop;
--     end;

      PortScan.Buildcycle.initialize (True);
      OPS.parallel_bulk_run
        (num_builders => Parameters.configuration.num_builders);
   end if;
   Replicant.finalize;


--     PortScan.release_ports_tree;

end synth;
