using System;
using kOS.MechJeb2.Addon.Attributes;
using kOS.MechJeb2.Addon.Core;
using kOS.MechJeb2.Addon.Utils;
using kOS.Safe.Encapsulation;
using kOS.Safe.Encapsulation.Suffixes;
using kOS.Safe.Exceptions;
using kOS.Safe.Utilities;

namespace kOS.MechJeb2.Addon.Wrapeers
{
    [KOSNomenclature("CoreWrapper")]
    public class MechJebCoreWrapper : BaseWrapper, IMechJebCoreWrapper
    {
        private MechJebAscentWrapper _ascentWrapper;
        private VesselStateWrapper _vesselStateWrapper;
        private MechJebInfoItemsWrapper _infoItemsWrapper;
        private MechJebNodeExecutorWrapper _nodeExecutorWrapper;
        private MechJebManeuverPlannerWrapper _maneuverPlannerWrapper;

        private const string NotReadyMessage =
            "MechJeb is not ready yet. This can happen after loading a saved game. " +
            "Please wait a moment and try again, or use ADDONS:MJ:INIT(TRUE) to force reinitialization.";

        private object GetMasterOrThrow()
        {
            var master = MasterMechJeb;
            if (master == null)
                throw new KOSException(NotReadyMessage);
            return master;
        }

        /// <summary>
        /// Override Initialize to clear all cached child wrappers when force=true.
        /// This ensures that after a save reload, all child wrappers are recreated
        /// with fresh module references instead of retaining stale ones.
        /// </summary>
        public override void Initialize(object coreInstance, bool force = false)
        {
            if (force)
            {
                // Clear all cached child wrappers - they hold stale module references
                // that point to destroyed Unity objects after scene/vessel changes
                _ascentWrapper = null;
                _vesselStateWrapper = null;
                _infoItemsWrapper = null;
                _nodeExecutorWrapper = null;
                _maneuverPlannerWrapper = null;
            }
            base.Initialize(coreInstance, force);
        }

        public MechJebAscentWrapper Ascent
        {
            get
            {
                var master = GetMasterOrThrow();
                if(_ascentWrapper != null && _ascentWrapper.Initialized) return _ascentWrapper;
                _ascentWrapper ??= new MechJebAscentWrapper();
                _ascentWrapper.Initialize(master);
                return _ascentWrapper;
            }
        }

        public VesselStateWrapper VesselState {
            get
            {
                var master = GetMasterOrThrow();
                if(_vesselStateWrapper != null && _vesselStateWrapper.Initialized) return _vesselStateWrapper;
                _vesselStateWrapper ??= new VesselStateWrapper();
                _vesselStateWrapper.Initialize(master);
                return _vesselStateWrapper;
            }
        }

        [ComputedModule("MechJebModuleInfoItems")]
        public MechJebInfoItemsWrapper InfoItems {
            get
            {
                var master = GetMasterOrThrow();
                if(_infoItemsWrapper != null && _infoItemsWrapper.Initialized) return _infoItemsWrapper;
                _infoItemsWrapper ??= new MechJebInfoItemsWrapper();
                _infoItemsWrapper.Initialize(master);
                return _infoItemsWrapper;
            } }

        [ComputedModule("MechJebModuleNodeExecutor")]
        public MechJebNodeExecutorWrapper NodeExecutor {
            get
            {
                var master = GetMasterOrThrow();
                if(_nodeExecutorWrapper != null && _nodeExecutorWrapper.Initialized) return _nodeExecutorWrapper;
                _nodeExecutorWrapper ??= new MechJebNodeExecutorWrapper();
                _nodeExecutorWrapper.Initialize(master);
                return _nodeExecutorWrapper;
            } }

        [ComputedModule("MechJebModuleManeuverPlanner")]
        public MechJebManeuverPlannerWrapper ManeuverPlanner {
            get
            {
                var master = GetMasterOrThrow();
                if(_maneuverPlannerWrapper != null && _maneuverPlannerWrapper.Initialized) return _maneuverPlannerWrapper;
                _maneuverPlannerWrapper ??= new MechJebManeuverPlannerWrapper();
                _maneuverPlannerWrapper.Initialize(master);
                return _maneuverPlannerWrapper;
            } }

        public Func<object, bool> Running { get; internal set; }

        protected override void InitializeSuffixes()
        {
            this.AddSuffix(new[] { "VESSEL", "VESSELINFO" }, new NoArgsSuffix<VesselStateWrapper>(() => VesselState));
            this.AddSuffix(new[] { "ASCENT", "ASCENTGUIDANCE" }, new NoArgsSuffix<MechJebAscentWrapper>(() => Ascent));
            this.AddSuffix(new[] { "INFO" }, new NoArgsSuffix<MechJebInfoItemsWrapper>(() => InfoItems));
            this.AddSuffix(new[] { "NODE", "NODEEXECUTOR" }, new NoArgsSuffix<MechJebNodeExecutorWrapper>(() => NodeExecutor));
            this.AddSuffix(new[] { "PLANNER", "MANEUVERPLANNER" }, new NoArgsSuffix<MechJebManeuverPlannerWrapper>(() => ManeuverPlanner));
            this.AddSuffix(new[] { "RUNNING" }, new NoArgsSuffix<BooleanValue>(() => Running(MasterMechJeb)));
        }

        public override string context() => nameof(MechJebCoreWrapper);
    }
}