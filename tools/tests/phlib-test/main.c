#include "tests.h"

int __cdecl wmain(int argc, wchar_t *argv[])
{
    NTSTATUS status;
    HANDLE instance = NULL;

    status = PhInitializePhLib(L"System Informer Tests", instance);
    assert(NT_SUCCESS(status));

    Test_basesup();
    Test_avltree();
    Test_format();
    Test_util();

    return 0;
}
