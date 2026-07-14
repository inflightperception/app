import re
from typing import Optional

from models.ofp_models import TafGroup


CHANGE_GROUP_PATTERN = re.compile(
    r"\b(PROB30\s+TEMPO|PROB40\s+TEMPO|PROB30|PROB40|TEMPO|BECMG|FM\d{4,6})\b"
)
INITIAL_PATTERN = re.compile(r"^FT\s+(\d{6})\s+(\d{4}/\d{4})\s*(.*)$")
VALIDITY_PATTERN = re.compile(r"^\d{4}/\d{4}$")
FM_PATTERN = re.compile(r"^FM(\d{4}|\d{6})$")
AT_PATTERN = re.compile(r"^AT(\d{4}|\d{6})$")
TL_PATTERN = re.compile(r"^TL(\d{4}|\d{6})$")


def normalize_taf_text(ft_raw: str) -> str:
    text = ft_raw.strip()
    if text.endswith("="):
        text = text[:-1]

    return re.sub(r"\s+", " ", text).strip()


def clean_conditions(value: str) -> Optional[str]:
    conditions = value.strip()
    return conditions or None


def parse_taf_groups(ft_raw: Optional[str]) -> list[TafGroup]:
    if not ft_raw or not ft_raw.strip():
        return []

    taf_text = normalize_taf_text(ft_raw)
    if not taf_text:
        return []

    initial_match = INITIAL_PATTERN.match(taf_text)
    if initial_match is None:
        return []

    issue_time = initial_match.group(1)
    validity = initial_match.group(2)
    remainder = initial_match.group(3)

    groups: list[TafGroup] = []
    change_matches = filter_change_group_matches(remainder, list(CHANGE_GROUP_PATTERN.finditer(remainder)))
    initial_conditions_end = change_matches[0].start() if change_matches else len(remainder)
    initial_conditions = remainder[:initial_conditions_end].strip()
    initial_raw_parts = ["FT", issue_time, validity]
    if initial_conditions:
        initial_raw_parts.append(initial_conditions)

    groups.append(
        TafGroup(
            group_type="INITIAL",
            issue_time=issue_time,
            validity=validity,
            raw=" ".join(initial_raw_parts),
            conditions=clean_conditions(initial_conditions),
        )
    )

    for index, match in enumerate(change_matches):
        group_start = match.start()
        group_end = change_matches[index + 1].start() if index + 1 < len(change_matches) else len(remainder)
        raw_group = remainder[group_start:group_end].strip()
        group = parse_change_group(raw_group, issue_time)

        if group is not None:
            groups.append(group)

    return groups


def filter_change_group_matches(
    taf_remainder: str,
    matches: list[re.Match],
) -> list[re.Match]:
    filtered_matches: list[re.Match] = []

    for match in matches:
        token = match.group(1)
        if token.startswith("FM") and is_embedded_fm_token(taf_remainder, match.start()):
            continue

        filtered_matches.append(match)

    return filtered_matches


def is_embedded_fm_token(taf_remainder: str, token_start: int) -> bool:
    prefix_tokens = taf_remainder[:token_start].split()
    if not prefix_tokens:
        return False

    previous_token = prefix_tokens[-1]
    return previous_token in {"TEMPO", "BECMG"}


def parse_change_group(raw_group: str, issue_time: Optional[str] = None) -> Optional[TafGroup]:
    tokens = raw_group.split()
    if not tokens:
        return None

    first_token = tokens[0]

    fm_match = FM_PATTERN.fullmatch(first_token)
    if fm_match is not None:
        return TafGroup(
            group_type="FM",
            validity=expand_taf_time_token(fm_match.group(1), issue_time),
            raw=raw_group,
            conditions=clean_conditions(" ".join(tokens[1:])),
        )

    if first_token in {"BECMG", "TEMPO", "PROB30", "PROB40"}:
        group_type = first_token
        validity_index = 1

        if first_token in {"PROB30", "PROB40"} and len(tokens) > 1 and tokens[1] == "TEMPO":
            group_type = f"{first_token}_TEMPO"
            validity_index = 2

        validity = None
        conditions_start = validity_index
        if len(tokens) > validity_index and VALIDITY_PATTERN.fullmatch(tokens[validity_index]):
            validity = tokens[validity_index]
            conditions_start = validity_index + 1
        elif len(tokens) > validity_index and FM_PATTERN.fullmatch(tokens[validity_index]):
            fm_match = FM_PATTERN.fullmatch(tokens[validity_index])
            group_type = f"{group_type}_FM"
            valid_from = expand_taf_time_token(fm_match.group(1), issue_time)
            conditions_start = validity_index + 1

            if len(tokens) > conditions_start and TL_PATTERN.fullmatch(tokens[conditions_start]):
                tl_match = TL_PATTERN.fullmatch(tokens[conditions_start])
                group_type = f"{group_type}_TL"
                valid_to = expand_taf_time_token(tl_match.group(1), issue_time)
                validity = build_taf_range_validity(valid_from, valid_to)
                conditions_start += 1
            else:
                validity = valid_from
        elif len(tokens) > validity_index and AT_PATTERN.fullmatch(tokens[validity_index]):
            at_match = AT_PATTERN.fullmatch(tokens[validity_index])
            group_type = f"{group_type}_AT"
            validity = expand_taf_time_token(at_match.group(1), issue_time)
            conditions_start = validity_index + 1

        return TafGroup(
            group_type=group_type,
            validity=validity,
            raw=raw_group,
            conditions=clean_conditions(" ".join(tokens[conditions_start:])),
        )

    return None


def expand_taf_time_token(value: str, issue_time: Optional[str]) -> str:
    if len(value) == 6:
        return value

    issue_day = issue_time[:2] if issue_time and re.fullmatch(r"\d{6}", issue_time) else "01"
    return f"{issue_day}{value}"


def build_taf_range_validity(valid_from: str, valid_to: str) -> str:
    if len(valid_from) == 6 and len(valid_to) == 6:
        return f"{valid_from}/{valid_to}"

    return f"{valid_from[:4]}/{valid_to[:4]}"
