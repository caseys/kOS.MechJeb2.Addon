using System;
using System.Linq;
using System.Reflection;
using kOS.AddOns;
using kOS.MechJeb2.Addon.Core;
using kOS.MechJeb2.Addon.Utils;
using kOS.MechJeb2.Addon.Wrapeers;
using kOS.Safe.Encapsulation;
using kOS.Safe.Encapsulation.Suffixes;
using kOS.Safe.Exceptions;
using kOS.Safe.Utilities;
using KSPBuildTools;

// ReSharper disable PossibleNullReferenceException

namespace kOS.MechJeb2.Addon
{
    [kOSAddon("MJ")]
    [KOSNomenclature("MJAddon")]
    public class Addon : Suffixed.Addon
    {
        private PartModule _mechJebCore;
        private bool _isCoreInitialized = false;

        public Addon(SharedObjects shared) : base(shared)
        {
            RegisterInitializer(InitializeSuffixes);
            TryInitializeMechJebCore();
        }

        public override BooleanValue Available()
        {
            Log.Debug("MJAddon.Available() called");
            // Check if GameEvents triggered reinitialization (save reload, vessel change, scene change)
            if (MechJebController.NeedsReinitialization)
            {
                Log.Debug("NeedsReinitialization flag set - forcing reinitialization");
                _isCoreInitialized = false;  // Reset local flag
                _mechJebCore = null;  // Clear stale reference
                bool success = TryInitializeMechJebCore(true);  // Force reinitialize
                if (success)
                {
                    MechJebController.ClearReinitializationFlag();
                }
                // If initialization failed, keep NeedsReinitialization true so we retry next time
            }
            else if (!_isCoreInitialized)
            {
                TryInitializeMechJebCore();
            }
            return MechJebController.IsAvailable;
        }

        private void InitializeSuffixes()
        {
            Log.Debug("Initializing kOS suffixes for MJAddon");
            AddSuffix("CORE",
                new NoArgsSuffix<MechJebCoreWrapper>(() =>
                    Available()
                        ? MechJebController.Instance
                        : throw new KOSUnavailableAddonException(
                            "CORE wrapper is unavailable. Please install a MechJeb2 and make sure the MechJebCore module is running on this vessel.",
                            "MechJeb2")));
            AddSuffix("INIT",
                new OneArgsSuffix<BooleanValue>((val) => TryInitializeMechJebCore(val),
                    "Manually (re)initializes the MechJeb core wrapper. Pass TRUE to force reinitialization."));
            AddSuffix("VERSION",
                new NoArgsSuffix<VersionInfo>(GetVersionInfo,
                    "Returns the kOS.MechJeb2.Addon version (major.minor.patch.build)."));
        }

        private VersionInfo GetVersionInfo()
        {
            var asm = Assembly.GetExecutingAssembly();
            var ver =  asm.GetName().Version;
            return new VersionInfo(ver.Major, ver.Minor, ver.Build, ver.Revision);
        }

        private bool TryInitializeMechJebCore(bool force = false)
        {
            Log.Debug($"Trying to initialize MechJebCore (force={force})");
            if (_isCoreInitialized && !force) return true;

            var vesselExtensionType = Constants.VesselExtensionName.GetTypeFromCache();
            if (vesselExtensionType == null)
            {
                Log.Error("[kOS.MJ] Cannot find MuMech.VesselExtensions type");
                return false;
            }

            var getMasterMechJeb =
                vesselExtensionType.GetMethod("GetMasterMechJeb", BindingFlags.Public | BindingFlags.Static);

            // Use FlightGlobals.ActiveVessel instead of shared.Vessel
            // shared.Vessel may be stale after save reload, but FlightGlobals is always current
            var vessel = FlightGlobals.ActiveVessel ?? shared.Vessel;

            // Check if vessel is valid (not null and not a destroyed Unity object)
            if (vessel == null || getMasterMechJeb == null)
            {
                Log.Debug("Vessel or GetMasterMechJeb is null");
                return false;
            }

            // Additional check: vessel might be a "fake null" (destroyed Unity object)
            try
            {
                // Accessing any property on a destroyed Unity object throws
                var _ = vessel.vesselName;
            }
            catch
            {
                Log.Debug("Vessel is a destroyed Unity object (fake null)");
                return false;
            }

            try
            {
                var core = getMasterMechJeb?.Invoke(null, new object[] { vessel }) as PartModule;

                if (core == null)
                {
                    Log.Debug("Cannot find MechJebCore running module - MechJeb may not be initialized yet");
                    return false;
                }

                _mechJebCore = core;
                Log.Debug("MechJebCore instance initialized successfully");
            }
            catch (Exception e)
            {
                Log.Exception(e);
                return false;
            }

            MechJebController.Instance.Initialize(_mechJebCore, force);
            _isCoreInitialized = true;
            return true;
        }
    }
}