// g++ -g -O0 -o ex ex.cpp
#include <iostream>
using namespace std;

void hello()
{
    int x = 1;
    /*cout << x << endl;*/
    cout << "Hello" << endl;
}

int main(int argc, char* argv[])
{
    for (int i = 0; i < argc; i++) {
        cout << argv[i] << endl;
    }
    int x;
    // cin >> x;
    // cout << x << endl;
    hello();
    return 0;
}
