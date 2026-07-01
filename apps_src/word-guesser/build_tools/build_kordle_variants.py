# 꼬들(6자모)·꼬오오오오들(12자모) 단어 사전 빌드.
#
# 입력: c:\tmp\kordle_raw\kordle.js (kordle.kr 번들), koooo.js (koooo.kordle.kr 번들)
#   두 번들 모두 정답/추측 단어를 "기본 자모 분해 문자열"(예 꼬들='ㄱㄱㅗㄷㅡㄹ') 배열로 담고 있음.
# 출력: Word-Guesser/assets/
#   kordle6_answers.txt, kordle6_guesses.txt   (꼬들, 6자모)
#   kordle12_answers.txt, kordle12_guesses.txt (꼬오오오오들, 12자모)
#   각 줄 = 표시용 단어(자모→한글 재조합 성공 시 한글, 실패 시 자모열).
#   앱이 이 단어를 다시 분해하면 항상 원래 자모열이 나오도록 보장(라운드트립 검증).
#
# 실행: py build_tools\build_kordle_variants.py
#
# ignore_for_file: n/a (python)

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = r"c:\tmp\kordle_raw"
ASSETS = os.path.join(ROOT, "assets")

BASIC_CONS = list("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ")
BASIC_VOW = list("ㅏㅑㅓㅕㅗㅛㅜㅠㅡㅣ")
BASIC = set(BASIC_CONS + BASIC_VOW)

CHO = list("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
JUNG = list("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
JONG = [""] + list("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")

CHO_SPLIT = {"ㄲ": "ㄱㄱ", "ㄸ": "ㄷㄷ", "ㅃ": "ㅂㅂ", "ㅆ": "ㅅㅅ", "ㅉ": "ㅈㅈ"}
JUNG_SPLIT = {"ㅐ": "ㅏㅣ", "ㅒ": "ㅑㅣ", "ㅔ": "ㅓㅣ", "ㅖ": "ㅕㅣ", "ㅘ": "ㅗㅏ",
              "ㅙ": "ㅗㅏㅣ", "ㅚ": "ㅗㅣ", "ㅝ": "ㅜㅓ", "ㅞ": "ㅜㅓㅣ",
              "ㅟ": "ㅜㅣ", "ㅢ": "ㅡㅣ"}
JONG_SPLIT = {"ㄲ": "ㄱㄱ", "ㄳ": "ㄱㅅ", "ㄵ": "ㄴㅈ", "ㄶ": "ㄴㅎ", "ㄺ": "ㄹㄱ",
              "ㄻ": "ㄹㅁ", "ㄼ": "ㄹㅂ", "ㄽ": "ㄹㅅ", "ㄾ": "ㄹㅌ", "ㄿ": "ㄹㅍ",
              "ㅀ": "ㄹㅎ", "ㅄ": "ㅂㅅ", "ㅆ": "ㅅㅅ"}


def decompose(word):
    """한글/자모 문자열 → 기본 자모 리스트 (쌍자음·복합모음·겹받침 모두 분해)."""
    out = []
    for ch in word:
        code = ord(ch)
        if 0xAC00 <= code <= 0xD7A3:
            s = code - 0xAC00
            cho, jung, jong = CHO[s // 588], JUNG[(s % 588) // 28], JONG[s % 28]
            out += list(CHO_SPLIT.get(cho, cho))
            out += list(JUNG_SPLIT.get(jung, jung))
            if jong:
                out += list(JONG_SPLIT.get(jong, jong))
        else:
            out.append(ch)
    return out


# 재조합용 결합표 (분해의 역)
VOW_COMBINE = {("ㅗ", "ㅏ"): "ㅘ", ("ㅗ", "ㅣ"): "ㅚ", ("ㅜ", "ㅓ"): "ㅝ",
               ("ㅜ", "ㅣ"): "ㅟ", ("ㅡ", "ㅣ"): "ㅢ", ("ㅏ", "ㅣ"): "ㅐ",
               ("ㅓ", "ㅣ"): "ㅔ", ("ㅑ", "ㅣ"): "ㅒ", ("ㅕ", "ㅣ"): "ㅖ",
               ("ㅘ", "ㅣ"): "ㅙ", ("ㅝ", "ㅣ"): "ㅞ"}
CHO_DOUBLE = {("ㄱ", "ㄱ"): "ㄲ", ("ㄷ", "ㄷ"): "ㄸ", ("ㅂ", "ㅂ"): "ㅃ",
              ("ㅅ", "ㅅ"): "ㅆ", ("ㅈ", "ㅈ"): "ㅉ"}
JONG_COMBINE = {("ㄱ", "ㄱ"): "ㄲ", ("ㄱ", "ㅅ"): "ㄳ", ("ㄴ", "ㅈ"): "ㄵ",
                ("ㄴ", "ㅎ"): "ㄶ", ("ㄹ", "ㄱ"): "ㄺ", ("ㄹ", "ㅁ"): "ㄻ",
                ("ㄹ", "ㅂ"): "ㄼ", ("ㄹ", "ㅅ"): "ㄽ", ("ㄹ", "ㅌ"): "ㄾ",
                ("ㄹ", "ㅍ"): "ㄿ", ("ㄹ", "ㅎ"): "ㅀ", ("ㅂ", "ㅅ"): "ㅄ",
                ("ㅅ", "ㅅ"): "ㅆ"}
CHO_SET = set(CHO)
JUNG_SET = set(JUNG)


def compose(jamos):
    """기본 자모 리스트 → 한글 문자열 (두벌식 오토마타). 실패 부분은 자모 그대로."""
    out = []
    cho = jung = jong = None

    def flush():
        nonlocal cho, jung, jong
        if cho is None and jung is None and jong is None:
            return
        if cho is not None and jung is not None:
            ci, ji = CHO.index(cho), JUNG.index(jung)
            ki = JONG.index(jong) if jong else 0
            out.append(chr(0xAC00 + (ci * 21 + ji) * 28 + ki))
        else:
            for j in (cho, jung, jong):
                if j:
                    out.append(j)
        cho = jung = jong = None

    for x in jamos:
        if x in BASIC_VOW:
            if cho is None:
                flush()
                out.append(x)
            elif jung is None:
                jung = x
            elif jong is None:
                c = VOW_COMBINE.get((jung, x))
                if c:
                    jung = c
                else:
                    flush()
                    out.append(x)
            else:
                # jong + vowel: 마지막 자음을 다음 음절 초성으로 (정상 단어에선 거의 없음)
                parts = list(JONG_SPLIT.get(jong, jong))
                moved = parts[-1]
                rest = parts[:-1]
                jong = (rest[0] if len(rest) == 1
                        else JONG_COMBINE.get(tuple(rest)) if len(rest) == 2
                        else None)
                flush()
                cho, jung, jong = moved, x, None
        else:  # consonant
            if cho is None:
                cho = x
            elif jung is None:
                d = CHO_DOUBLE.get((cho, x))
                if d:
                    cho = d
                else:
                    flush()
                    cho = x
            elif jong is None:
                jong = x
            else:
                c = JONG_COMBINE.get((jong, x))
                if c:
                    jong = c
                else:
                    flush()
                    cho = x
    flush()
    return "".join(out)


def extract_clusters(js_text, length):
    """번들에서 '정확히 length 개의 기본 자모로만 된 따옴표 문자열'을 위치별 클러스터로 묶어
    가장 큰 두 클러스터(추측, 정답)를 (answers, guesses) 로 반환."""
    jamo_class = "".join(BASIC)
    pat = re.compile(r'"([' + re.escape(jamo_class) + r']{' + str(length) + r'})"')
    matches = [(m.start(), m.group(1)) for m in pat.finditer(js_text)]
    if not matches:
        return [], []
    clusters = []
    cur = [matches[0]]
    for prev, nxt in zip(matches, matches[1:]):
        if nxt[0] - prev[0] <= 60:
            cur.append(nxt)
        else:
            clusters.append(cur)
            cur = [nxt]
    clusters.append(cur)
    clusters.sort(key=len, reverse=True)
    guesses = [w for _, w in clusters[0]]
    answers = [w for _, w in clusters[1]] if len(clusters) > 1 else []
    return answers, guesses


def build(name, length):
    js = open(os.path.join(RAW, f"{name}.js"), encoding="utf-8").read()
    # 미니파이된 번들은 자모를 \uXXXX 로 이스케이프 → 실제 문자로 디코드
    js = re.sub(r"\\u([0-9a-fA-F]{4})", lambda m: chr(int(m.group(1), 16)), js)
    answers, guesses = extract_clusters(js, length)
    # 정답이 추측 풀보다 작아야 정상 (아니면 스왑)
    if len(answers) > len(guesses):
        answers, guesses = guesses, answers
    return answers, guesses


def to_display(jamo_str):
    """자모열 → (표시용 단어, 라운드트립 성공 여부)."""
    kor = compose(list(jamo_str))
    ok = "".join(decompose(kor)) == jamo_str
    return (kor if ok else jamo_str), ok


def write_variant(prefix, length, answers, guesses):
    os.makedirs(ASSETS, exist_ok=True)
    stats = {}
    for kind, words in (("answers", answers), ("guesses", guesses)):
        disp, fails = [], 0
        for j in words:
            d, ok = to_display(j)
            disp.append(d)
            if not ok:
                fails += 1
        # answers 는 guesses 에도 포함되도록 (유효 추측 = 합집합)
        path = os.path.join(ASSETS, f"{prefix}_{kind}.txt")
        open(path, "w", encoding="utf-8").write("\n".join(disp))
        stats[kind] = (len(disp), fails)
    return stats


def main():
    for prefix, name, length in (("kordle6", "kordle", 6), ("kordle12", "koooo", 12)):
        answers, guesses = build(name, length)
        # 합집합: 유효추측 = answers ∪ guesses
        gset = list(dict.fromkeys(guesses + answers))
        stats = write_variant(prefix, length, answers, gset)
        print(f"[{prefix}] answers={stats['answers'][0]}(fail {stats['answers'][1]}) "
              f"guesses={stats['guesses'][0]}(fail {stats['guesses'][1]})")
        sample = [to_display(a)[0] for a in answers[:12]]
        print("   sample answers:", ", ".join(sample))


if __name__ == "__main__":
    main()
