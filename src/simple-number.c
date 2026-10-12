/* Conservative fast path: unsupported inputs return NA for the R parser. */
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Utils.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>
#include <string.h>

static int digit(unsigned char c) { return c >= '0' && c <= '9'; }

static int ascii_prefix(const char *p, const char *upper)
{
    for (int i = 0; i < 3; ++i)
        if (p[i] != upper[i] && p[i] != upper[i] + ('a' - 'A')) return 0;
    return 1;
}

static double simple_number(const char *text, double header)
{
    const char *p = text;
    int accounting = *p == '(';
    if (accounting) ++p;
    int signed_before = *p == '-' || *p == '+';
    int negative = *p == '-';
    if (signed_before) ++p;
    int currency = 0;
    if (ascii_prefix(p, "RMB") || ascii_prefix(p, "CNY")) currency = 3;
    else if (strncmp(p, "\xc2\xa5", 2) == 0) currency = 2;
    else if (strncmp(p, "\xe4\xba\xba\xe6\xb0\x91\xe5\xb8\x81", 9) == 0) currency = 9;
    p += currency;
    int signed_after = *p == '-' || *p == '+';
    if ((signed_before && signed_after) || (accounting && (signed_before || signed_after)))
        return NA_REAL;
    if (signed_after) { negative = *p == '-'; ++p; }
    const char *number = p;
    int digits = 0;
    while (digit((unsigned char)*p)) { ++p; ++digits; }
    if (*p == '.') {
        ++p;
        const char *fraction = p;
        while (digit((unsigned char)*p)) ++p;
        if (p == fraction) return NA_REAL;
    } else if (!digits) return NA_REAL;
    if (*p == 'e' || *p == 'E') {
        ++p;
        if (*p == '+' || *p == '-') ++p;
        const char *exponent = p;
        while (digit((unsigned char)*p)) ++p;
        if (p == exponent) return NA_REAL;
    }
    char *end;
    double value = R_strtod(number, &end);
    if (end != p || !R_FINITE(value)) return NA_REAL;
    double multiplier = 1;
    int explicit_unit = currency != 0;
    if (strncmp(p, "\xe4\xb8\x87\xe4\xba\xbf", 6) == 0) {
        multiplier = 1e12; p += 6; explicit_unit = 1;
    } else if (strncmp(p, "\xe4\xb8\x87", 3) == 0) {
        multiplier = 1e4; p += 3; explicit_unit = 1;
    } else if (strncmp(p, "\xe4\xba\xbf", 3) == 0) {
        multiplier = 1e8; p += 3; explicit_unit = 1;
    } else if (strncmp(p, "\xe5\x8d\x83\xe5\x85\x83", 6) == 0) {
        multiplier = 1e3; p += 3; explicit_unit = 1;
    }
    if (strncmp(p, "\xe5\x85\x83", 3) == 0) { p += 3; explicit_unit = 1; }
    int percent = *p == '%';
    if (percent) ++p;
    if (accounting) {
        if (*p != ')') return NA_REAL;
        ++p;
        negative = 1;
    }
    if (*p || (percent && explicit_unit)) return NA_REAL;
    if (R_FINITE(header)) {
        if (percent || (explicit_unit && multiplier != header)) return NA_REAL;
        if (!explicit_unit) multiplier = header;
    }
    value *= multiplier;
    if (!R_FINITE(value)) return NA_REAL;
    if (negative) value = -value;
    if (percent) value /= 100;
    return value;
}

static SEXP simple_numbers(SEXP text, SEXP header)
{
    if (TYPEOF(text) != STRSXP || TYPEOF(header) != REALSXP || XLENGTH(header) != 1)
        Rf_error("Invalid native parser arguments.");
    R_xlen_t size = XLENGTH(text);
    SEXP values = PROTECT(Rf_allocVector(REALSXP, size));
    double unit = REAL(header)[0];
    for (R_xlen_t i = 0; i < size; ++i) {
        if (i % 16384 == 0) R_CheckUserInterrupt();
        SEXP cell = STRING_ELT(text, i);
        REAL(values)[i] = cell == NA_STRING || Rf_getCharCE(cell) == CE_BYTES ? NA_REAL :
            simple_number(Rf_translateCharUTF8(cell), unit);
    }
    UNPROTECT(1);
    return values;
}

static SEXP normalize_characters(SEXP text)
{
    if (TYPEOF(text) != STRSXP) Rf_error("Invalid normalization arguments.");
    R_xlen_t size = XLENGTH(text);
    size_t capacity = 1;
    for (R_xlen_t i = 0; i < size; ++i) {
        if (i % 16384 == 0) R_CheckUserInterrupt();
        SEXP cell = STRING_ELT(text, i);
        if (cell == NA_STRING) continue;
        if (Rf_getCharCE(cell) == CE_BYTES)
            Rf_error("translating strings with bytes encoding is not allowed");
        size_t length = strlen(Rf_translateCharUTF8(cell)) + 1;
        if (length > capacity) capacity = length;
    }
    char *buffer = (char *) R_alloc(capacity, 1);
    SEXP result = PROTECT(Rf_allocVector(STRSXP, size));
    for (R_xlen_t i = 0; i < size; ++i) {
        if (i % 16384 == 0) R_CheckUserInterrupt();
        SEXP cell = STRING_ELT(text, i);
        if (cell == NA_STRING) { SET_STRING_ELT(result, i, cell); continue; }
        const unsigned char *p = (const unsigned char *) Rf_translateCharUTF8(cell);
        char *out = buffer;
        while (*p) {
            unsigned int code = 0;
            if (p[0] >= 0xe0 && p[0] <= 0xef && p[1] && p[2] &&
                (p[1] & 0xc0) == 0x80 && (p[2] & 0xc0) == 0x80)
                code = ((p[0] & 0x0f) << 12) | ((p[1] & 0x3f) << 6) | (p[2] & 0x3f);
            if (code == 0xfffe || code == 0xffff)
                Rf_error("Invalid Unicode noncharacter in normalization input.");
            int replacement = 0;
            if (code >= 0xff10 && code <= 0xff19) replacement = '0' + code - 0xff10;
            else switch (code) {
                case 0xff0d: case 0x2212: case 0xfe63: case 0x2013: replacement = '-'; break;
                case 0xff0e: replacement = '.'; break;
                case 0xff0c: replacement = ','; break;
                case 0xff05: replacement = '%'; break;
                case 0xff0b: replacement = '+'; break;
                case 0xff08: replacement = '('; break;
                case 0xff09: replacement = ')'; break;
                case 0xff1c: replacement = '<'; break;
                case 0xff1e: replacement = '>'; break;
                case 0xff1d: replacement = '='; break;
                case 0xff25: replacement = 'E'; break;
                case 0xff45: replacement = 'e'; break;
            }
            if (replacement) { *out++ = (char) replacement; p += 3; }
            else if (code == 0xffe5) { *out++ = (char) 0xc2; *out++ = (char) 0xa5; p += 3; }
            else *out++ = (char) *p++;
        }
        *out = '\0';
        SET_STRING_ELT(result, i, Rf_mkCharCE(buffer, CE_UTF8));
    }
    Rf_setAttrib(result, R_NamesSymbol, Rf_getAttrib(text, R_NamesSymbol));
    UNPROTECT(1);
    return result;
}

static const R_CallMethodDef methods[] = {
    {"simple_numbers", (DL_FUNC) &simple_numbers, 2},
    {"normalize_characters", (DL_FUNC) &normalize_characters, 1},
    {NULL, NULL, 0}
};

void attribute_visible R_init_cncleanr(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, methods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
