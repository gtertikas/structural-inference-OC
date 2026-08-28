# Anonymised behavioural dataset

Structural inference task, online confirmatory study (N = 313).
Supports: Tertikas, Trudel, Seow, Klein-Flügge & Hauser, *Impaired Updating
and Maintenance of Latent Structural Associations Underlie Cognitive
Inflexibility along an Obsessive-Compulsive Dimension*.
Preregistration: https://osf.io/eq56y/

`subject_id` is a sequential integer (1-313) assigned at export time and
carries no relation to Prolific participant IDs, order of participation, or
any other original identifier. No Prolific ID, IP address, timestamp,
free-text response, or demographic field (age/sex/nationality) is included
in either file.

## trial_data.csv (86,388 rows — one row per subject × trial, main task phase)

| column | meaning |
|---|---|
| subject_id | anonymous subject key (1-313) |
| trial | trial number within the main task (1-280ish, per subject) |
| condition_FB | 1 = feedback (FB) trial, 0 = no-feedback (no-FB) trial |
| predictor_id | rocket identity (abstract item index, 1-4) |
| option_id | product identity (abstract item index, 1-4) |
| choice_accept | participant's response: 1 = accept, 0 = reject |
| correct_answer | ground-truth correct response for this rocket-product pair given current structure |
| feedback_outcome | outcome shown on FB trials (1 = correct/rewarded, 0 = incorrect, -1 = no feedback shown i.e. no-FB trial) |
| structural_change | 1 = a structural change (rocket or product swap) occurred at/around this trial |

## subject_summary.csv (313 rows — one row per subject)

| column | meaning |
|---|---|
| subject_id | anonymous subject key (1-313), matches trial_data.csv |
| n_structural_changes | number of structural changes the participant experienced (1-6) |
| factor_AD | anxiety-depression factor score (regression-weighted) |
| factor_SU | social-unease factor score |
| factor_OC | obsessive-compulsive factor score — the dimension of interest in the paper |
| quest_OCIR | Obsessive-Compulsive Inventory-Revised total |
| quest_ICAA | International Cognitive Ability Resource total correct |
| quest_LSAS_fear | Liebowitz Social Anxiety Scale, fear subscale total |
| quest_LSAS_avoid | Liebowitz Social Anxiety Scale, avoidance subscale total |
| quest_AMI | Apathy Motivation Index total |
| quest_BIS | Barratt Impulsiveness Scale total |
| quest_DASS | Depression Anxiety Stress Scale-42 total |
| quest_SSMS | Short Scales for Measuring Schizotypy total |
| quest_RSS | Rosenberg Self-Esteem Scale total |
