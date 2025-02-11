import asyncio
import sys

from spout.shared.base_handler import BaseHandler


class SpoutEvaluate(BaseHandler):
    async def evaluate(self, combined_inputs: str, separator: str, judging_criteria: str, explanation: str, spoutlet: str = None):
        try:
            result = await self.process_with_plugin(
                plugin_name="Evaluate",
                CombinedInputs=combined_inputs,
                Separator=separator if separator else "@@",
                JudgingCriteria=judging_criteria if judging_criteria else "quality",
                Explanation=explanation if explanation else "False",
                spoutlet=spoutlet
            )
            
            if 'python.exe' in sys.executable:
                print(result)
            else:
                return result
            
        except Exception as e:
            self.show_error_popup(f"An error occurred: {str(e)}")
            sys.exit(1)

if __name__ == "__main__":
    try:
        if len(sys.argv) >= 5:
            combined_inputs = sys.argv[1]
            separator = sys.argv[2]
            judging_criteria = sys.argv[3]
            explanation = sys.argv[4]
            spoutlet = sys.argv[5] if len(sys.argv) > 5 else None
            evaluator = SpoutEvaluate()
            asyncio.run(evaluator.evaluate(combined_inputs, separator, judging_criteria, explanation, spoutlet))
        else:
            SpoutEvaluate().show_error_popup("Incorrect number of parameters")
            sys.exit(1)
    except Exception as e:
        SpoutEvaluate().show_error_popup(f"An unhandled error occurred: {str(e)}")
        sys.exit(1)
