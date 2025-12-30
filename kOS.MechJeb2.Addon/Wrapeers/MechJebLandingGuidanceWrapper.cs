using System;
using System.Reflection;
using kOS.MechJeb2.Addon.Core;
using kOS.MechJeb2.Addon.Utils;
using kOS.Safe.Encapsulation;
using kOS.Safe.Encapsulation.Suffixes;
using kOS.Safe.Utilities;
using UnityEngine;

namespace kOS.MechJeb2.Addon.Wrapeers
{
    /// <summary>
    /// kOS wrapper for MechJeb's Landing Guidance module.
    /// Provides suffixes for preset landing sites and KSC targeting.
    /// </summary>
    /// <remarks>
    /// Uses lazy binding pattern - module binding is retried on each suffix
    /// access until successful, allowing for delayed module initialization.
    /// </remarks>
    [KOSNomenclature("LandingGuidanceWrapper")]
    public class MechJebLandingGuidanceWrapper : BaseWrapper
    {
        private readonly object _userIdentity = new object();

        // Method to get LandingGuidance module via GetComputerModule(string)
        private MethodInfo _getComputerModuleMethod;

        // Methods - MethodInfo to invoke on fresh module
        private MethodInfo _setAndLandTargetKSCMethod;
        private MethodInfo _landSomewhereMethod;

        // Static landing sites field info
        private FieldInfo _landingSitesField;
        private bool _bindingComplete;

        // Log throttling - only log binding issues once per scene
        private bool _loggedModuleNotAvailable;
        private bool _loggedBindingIncomplete;

        /// <summary>
        /// Gets a fresh LandingGuidance module from MasterMechJeb every time.
        /// This avoids stale reference issues after save reloads.
        /// </summary>
        private object GetLandingGuidanceModule()
        {
            if (MasterMechJeb == null) return null;
            return _getComputerModuleMethod?.Invoke(MasterMechJeb,
                new object[] { "MechJebModuleLandingGuidance" });
        }

        protected override void BindObject()
        {
            var masterMechJeb = MasterMechJeb;

            // Cache the method to get LandingGuidance module fresh each time
            // MechJebCore has GetComputerModule(string type) method
            _getComputerModuleMethod = masterMechJeb.GetType().GetMethod("GetComputerModule",
                new Type[] { typeof(string) });

            // Get module once to find its type for binding methods
            EnsureBinding();
        }

        protected override void InitializeSuffixes()
        {
            AddSuffix("LANDINGSITES",
                new NoArgsSuffix<ListValue>(GetLandingSites,
                    "List of preset landing site names"));

            AddSuffix("SETANDLANDTARGETKSC",
                new NoArgsSuffix<BooleanValue>(SetAndLandTargetKSC,
                    "Set KSC as target and start landing"));

            AddSuffix("LANDSOMEWHERE",
                new NoArgsSuffix<BooleanValue>(LandSomewhere,
                    "Start untargeted landing"));
        }

        public override string context() => nameof(MechJebLandingGuidanceWrapper);

        private ListValue GetLandingSites()
        {
            var result = new ListValue();

            if (!Initialized) return result;
            if (!EnsureBinding()) return result;

            try
            {
                // Access static field directly
                var sites = _landingSitesField?.GetValue(null);
                if (sites == null) return result;

                // Validate type before casting
                if (!(sites is System.Collections.IEnumerable sitesList))
                {
                    UnityEngine.Debug.Log($"[kOS.MechJeb2.Addon] LandingSites field is not IEnumerable: {sites.GetType().Name}");
                    return result;
                }

                foreach (var site in sitesList)
                {
                    if (site == null) continue;

                    // Get the Name field from the LandingSite struct using reflection
                    var siteType = site.GetType();
                    var nameField = siteType.GetField("Name");
                    if (nameField != null)
                    {
                        var name = nameField.GetValue(site) as string;
                        if (!string.IsNullOrEmpty(name))
                        {
                            result.Add(new StringValue(name));
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                UnityEngine.Debug.Log($"[kOS.MechJeb2.Addon] GetLandingSites error: {ex}");
            }

            return result;
        }

        private BooleanValue SetAndLandTargetKSC()
        {
            if (!Initialized) return false;
            try
            {
                if (!EnsureBinding()) return false;

                var guidance = GetLandingGuidanceModule();
                if (guidance == null || _setAndLandTargetKSCMethod == null) return false;

                _setAndLandTargetKSCMethod.Invoke(guidance, null);
                return true;
            }
            catch (Exception ex)
            {
                UnityEngine.Debug.Log($"[kOS.MechJeb2.Addon] SetAndLandTargetKSC failed: {ex}");
                return false;
            }
        }

        private BooleanValue LandSomewhere()
        {
            if (!Initialized) return false;
            try
            {
                if (!EnsureBinding()) return false;

                var guidance = GetLandingGuidanceModule();
                if (guidance == null || _landSomewhereMethod == null) return false;

                _landSomewhereMethod.Invoke(guidance, null);
                return true;
            }
            catch (Exception ex)
            {
                UnityEngine.Debug.Log($"[kOS.MechJeb2.Addon] LandSomewhere failed: {ex}");
                return false;
            }
        }

        private bool EnsureBinding()
        {
            if (_bindingComplete) return true;

            var guidance = GetLandingGuidanceModule();
            if (guidance == null)
            {
                if (!_loggedModuleNotAvailable)
                {
                    UnityEngine.Debug.Log("[kOS.MechJeb2.Addon] LandingGuidance: Module not available yet");
                    _loggedModuleNotAvailable = true;
                }
                return false;
            }

            var guidanceType = guidance.GetType();

            _setAndLandTargetKSCMethod ??= guidanceType.GetMethod("SetAndLandTargetKSC",
                BindingFlags.Public | BindingFlags.Instance);
            _landSomewhereMethod ??= guidanceType.GetMethod("LandSomewhere",
                BindingFlags.Public | BindingFlags.Instance);
            _landingSitesField ??= guidanceType.GetField("LandingSites",
                BindingFlags.Public | BindingFlags.Static);

            _bindingComplete = _setAndLandTargetKSCMethod != null &&
                               _landSomewhereMethod != null &&
                               _landingSitesField != null;

            if (!_bindingComplete && !_loggedBindingIncomplete)
            {
                UnityEngine.Debug.Log($"[kOS.MechJeb2.Addon] LandingGuidance: Binding incomplete - " +
                    $"SetAndLandTargetKSC={_setAndLandTargetKSCMethod != null}, " +
                    $"LandSomewhere={_landSomewhereMethod != null}, " +
                    $"LandingSites={_landingSitesField != null}");
                _loggedBindingIncomplete = true;
            }

            return _bindingComplete;
        }
    }
}
