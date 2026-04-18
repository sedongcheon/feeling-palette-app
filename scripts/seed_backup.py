#!/usr/bin/env python3
"""Feeling Palette seed generator.

Produces a backup JSON file compatible with
`lib/services/backup_service.dart` (schema_version=1).
Import it via the app's 백업/복원 screen.

Usage:
    python3 scripts/seed_backup.py \
        --count 3000 --days 365 --analyzed-ratio 0.8 \
        --out feeling-palette-seed.json
"""

from __future__ import annotations

import argparse
import json
import random
import uuid
from datetime import datetime, timedelta, timezone

EMOTIONS = [
    ("joy",        "#FFD700", "기쁨"),
    ("sadness",    "#4A90D9", "슬픔"),
    ("anger",      "#E74C3C", "분노"),
    ("anxiety",    "#9B59B6", "불안"),
    ("calm",       "#2ECC71", "평온"),
    ("excitement", "#FF69B4", "설렘"),
]

CONTENT_TEMPLATES = {
    "joy": [
        "오늘은 정말 기분 좋은 하루였다. {detail}",
        "{detail} 덕분에 오랜만에 크게 웃었다.",
        "별것 아닌 일에도 즐거움을 느낀 하루. {detail}",
    ],
    "sadness": [
        "왠지 모르게 마음이 가라앉는 하루. {detail}",
        "{detail} 생각이 자꾸 나서 힘들었다.",
        "조용히 혼자 있고 싶은 날이었다. {detail}",
    ],
    "anger": [
        "오늘 {detail} 때문에 속이 상했다.",
        "{detail} 생각할수록 화가 난다.",
        "참아보려 했지만 결국 폭발해버렸다. {detail}",
    ],
    "anxiety": [
        "{detail} 걱정에 잠이 오지 않았다.",
        "내일이 두려웠다. {detail}",
        "{detail} 자꾸 신경 쓰여서 아무것도 손에 안 잡힌다.",
    ],
    "calm": [
        "조용하고 평범한 하루였다. {detail}",
        "{detail} 하며 마음이 차분해졌다.",
        "오늘은 별일 없이 흘러갔다. {detail}",
    ],
    "excitement": [
        "{detail} 기대돼서 마음이 들뜬다.",
        "오늘 {detail} 생각만 해도 설렌다.",
        "{detail} 덕분에 하루 종일 기분이 날아갈 것 같았다.",
    ],
}

DETAILS = [
    "친구와 점심을 먹으며 수다를 떨었고",
    "새로 시작한 운동을 꾸준히 하고 있고",
    "오랜만에 가족에게 연락을 해보니",
    "퇴근길 노을이 유난히 예뻤고",
    "읽던 책의 한 문장이 마음에 남아서",
    "주말에 계획한 여행이",
    "업무에서 작은 성취가 있었고",
    "고양이가 내 무릎에 올라와서",
    "비 오는 소리를 들으며 커피를 마셨고",
    "옛날 사진을 정리하다가",
    "예전에 좋아하던 노래를 다시 들으며",
    "새로운 취미에 도전했는데",
    "길에서 모르는 사람이 인사를 건네서",
    "시험 결과가 나왔는데",
    "집 앞 골목에 핀 꽃을 보며",
]

AI_COMMENTS = {
    "joy":        "오늘의 기쁨을 오래 기억할 수 있도록 작은 메모를 남겨보세요.",
    "sadness":    "슬픈 감정도 소중한 신호예요. 충분히 쉬어도 괜찮아요.",
    "anger":      "잠시 숨을 고르고 나의 마음을 돌아보는 시간을 가져보세요.",
    "anxiety":    "불안한 마음일수록 내 몸의 감각에 집중해보는 게 도움이 돼요.",
    "calm":       "이 평온함이 오늘 하루를 단단하게 받쳐주었네요.",
    "excitement": "설렘은 삶에 빛을 더해주는 감정이에요. 그 순간을 만끽하세요.",
}


def sample_scores(primary: str, rng: random.Random) -> dict[str, int]:
    """Return per-emotion scores with the primary one highest."""
    scores = {name: 0 for name, _, _ in EMOTIONS}
    scores[primary] = rng.randint(55, 95)
    for name, _, _ in EMOTIONS:
        if name == primary:
            continue
        scores[name] = rng.randint(0, 40)
    return scores


def make_entry(date: datetime, analyzed: bool, rng: random.Random) -> dict:
    primary, color, _label = rng.choice(EMOTIONS)
    detail = rng.choice(DETAILS)
    content = rng.choice(CONTENT_TEMPLATES[primary]).format(detail=detail).strip()

    ts = int(date.timestamp() * 1000)
    entry = {
        "id": str(uuid.uuid4()),
        "date": date.strftime("%Y-%m-%d"),
        "content": content,
        "primary_emotion": primary if analyzed else "calm",
        "emotions": sample_scores(primary, rng) if analyzed else {
            name: 0 for name, _, _ in EMOTIONS
        },
        "ai_comment": AI_COMMENTS[primary] if analyzed else "",
        "color": color if analyzed else "#9CA3AF",
        "created_at": ts,
        "updated_at": ts,
        "analysis_count": rng.randint(1, 3) if analyzed else 0,
    }
    return entry


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--count", type=int, default=3000)
    p.add_argument("--days", type=int, default=365,
                   help="Spread entries across the last N days (inclusive of today).")
    p.add_argument("--analyzed-ratio", type=float, default=0.8)
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--out", default="feeling-palette-seed.json")
    args = p.parse_args()

    rng = random.Random(args.seed)
    today = datetime.now(timezone.utc).astimezone()
    start = today - timedelta(days=args.days - 1)

    entries = []
    for i in range(args.count):
        # Uniformly distribute across the window, then jitter the intra-day time.
        day_offset = rng.randint(0, args.days - 1)
        base = start + timedelta(days=day_offset)
        t = base.replace(
            hour=rng.randint(7, 23),
            minute=rng.randint(0, 59),
            second=rng.randint(0, 59),
            microsecond=0,
        )
        analyzed = rng.random() < args.analyzed_ratio
        entries.append(make_entry(t, analyzed, rng))

    # Sort newest first so the timeline/calendar order matches a real dataset.
    entries.sort(key=lambda e: e["created_at"], reverse=True)

    payload = {
        "app": "feeling_palette",
        "schema_version": 1,
        "exported_at": datetime.now(timezone.utc).astimezone().isoformat(),
        "count": len(entries),
        "entries": entries,
    }

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False)

    analyzed_count = sum(1 for e in entries if e["analysis_count"] > 0)
    print(f"Wrote {len(entries)} entries → {args.out}")
    print(f"  analyzed: {analyzed_count} ({analyzed_count / len(entries):.0%})")
    print(f"  window:   {start.strftime('%Y-%m-%d')} ~ {today.strftime('%Y-%m-%d')}")


if __name__ == "__main__":
    main()
