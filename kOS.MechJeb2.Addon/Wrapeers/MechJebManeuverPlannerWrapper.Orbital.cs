using kOS.Safe.Encapsulation;
using kOS.Safe.Encapsulation.Suffixes;

namespace kOS.MechJeb2.Addon.Wrapeers
{
    /// <summary>
    /// Orbital operations partial class for MechJebManeuverPlannerWrapper
    /// Contains operations for orbital adjustments: COURSECORRECTION, ELLIPTICIZE, ECCENTRICITY
    /// </summary>
    public partial class MechJebManeuverPlannerWrapper
    {
        /// <summary>
        /// Initialize orbital operation suffixes
        /// Called from main InitializeSuffixes() method
        /// </summary>
        partial void InitializeOrbitalSuffixes()
        {
            AddSuffix("COURSECORRECTION",
                new OneArgsSuffix<BooleanValue, ScalarValue>(
                    CourseCorrection,
                    "Fine-tune trajectory to target. Adjusts periapsis (bodies) or closest approach (vessels). Auto-timing. Params: finalPeA (m)"));
        }

        /// <summary>
        /// Course correction - fine-tune closest approach to target
        /// MechJeb: OperationCourseCorrection
        ///
        /// Optimizes periapsis for body targets or closest approach for vessel targets.
        /// Timing is calculated automatically by MechJeb (no timeRef parameter).
        /// </summary>
        /// <param name="finalPeA">Target periapsis (bodies) or closest approach (vessels) in meters</param>
        private BooleanValue CourseCorrection(ScalarValue finalPeA)
        {
            return ExecuteOperation("OperationCourseCorrection", null, op =>
            {
                // MechJeb expects CourseCorrectFinalPeA in kilometers, not meters
                SetEditableOnOperation(op, "CourseCorrectFinalPeA", (double)finalPeA / 1000.0);
            });
        }
    }
}
