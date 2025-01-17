
#include <utility>

#include "../../include/ir-util.hpp"

using namespace std;


// 寄存器和label的管理需要优化

int v_regs = 1;
int labels = 1;


TAC::TAC(const string &X, const string &Y, const string &Z, TAC_TYPE type)
        : X(std::move(preprocess_operand(X))),
          Y(std::move(preprocess_operand(Y))),
          Z(std::move(preprocess_operand(Z))),
          type(type) {}

string TAC::preprocess_operand(const string &str) {
    return isNumber(str) ? ("#" + str) : str;
}

bool isNumber(const string &str) {
    for (char const &c: str) {
        if (std::isdigit(c) == 0 or str.empty()) {
            return false;
        }
    }
    return true;
}


int translate_to_tac() {
    Node *Program = root_node;
    Node *ExtDefList = Program->child[0];
    for (auto *ExtDef: list_to_vector(ExtDefList)) {
        Node *Specifier = ExtDef->child[0];
        Node *FunDec = ExtDef->child[1];
        Node *CompSt = ExtDef->child[2];
        Node *CompFunDec = new Node(Node_Type::NOTHING, "CompFunDec", "", FunDec->line_num);
        CompFunDec->child.push_back(Specifier);
        CompFunDec->child.push_back(FunDec);
        translate_func_dec(CompFunDec);
        translate_compst(CompSt);
    }

    // Optimization
    duplicated_assign_optimization();
    label_optimization();
    return v_regs;
}

void print_tac_ir() {
    cout << ir_tac.size() << " TAC in total !" << endl;
    cout << v_regs << "variables in tatal" << endl;
    for (auto *temp: ir_tac) {
        cout << "---------------------------------------" << endl;
        cout << temp << endl;
    }

}

vector<Node *> list_to_vector(Node *List) {
    vector<Node *> result;
    while (!List->child.empty()) {
        result.push_back(List->child[0]);
        List = List->child[1];
    }
    return result;
}

// 这里的返回寄存器操作需要优化
string get_vital_register() {
    string reg = "v" + to_string(v_regs);
    v_regs++;
    return reg;
}

string get_label() {
    string reg = "label" + to_string(labels);
    labels++;
    return reg;
}


std::ostream &operator<<(std::ostream &lhs, const TAC *tac) {
    switch (tac->type) {
        case TAC_TYPE::LABEL:
            lhs << "LABEL " << tac->X << " :";
            break;
        case TAC_TYPE::FUNCTION:
            lhs << "FUNCTION " << tac->X << " :";
            break;
        case TAC_TYPE::ASSIGN:
            lhs << tac->X << " := " << tac->Y;
            break;
        case TAC_TYPE::ADDITION:
            lhs << tac->X << " := " << tac->Y << " + " << tac->Z;
            break;
        case TAC_TYPE::SUBTRACTION:
            lhs << tac->X << " := " << tac->Y << " - " << tac->Z;
            break;
        case TAC_TYPE::MULTIPLICATION:
            lhs << tac->X << " := " << tac->Y << " * " << tac->Z;
            break;
        case TAC_TYPE::DIVISION:
            lhs << tac->X << " := " << tac->Y << " / " << tac->Z;
            break;
        case TAC_TYPE::GOTO:
            lhs << "GOTO " << tac->X;
            break;
        case TAC_TYPE::RETURN:
            lhs << "RETURN " << tac->X;
            break;
        case TAC_TYPE::PARAM:
            lhs << "PARAM " << tac->X;
            break;
        case TAC_TYPE::ARG:
            lhs << "ARG " << tac->X;
            break;
        case TAC_TYPE::CALL:
            lhs << tac->X << " := CALL " << tac->Y;
            break;
        case TAC_TYPE::READ:
            lhs << "READ " << tac->X;
            break;
        case TAC_TYPE::WRITE:
            lhs << "WRITE " << tac->X;
            break;
        case TAC_TYPE::CONDITION_LT:
            lhs << "IF " << tac->X << " < " << tac->Y << " GOTO " << tac->Z;
            break;
        case TAC_TYPE::CONDITION_LE:
            lhs << "IF " << tac->X << " <= " << tac->Y << " GOTO " << tac->Z;
            break;
        case TAC_TYPE::CONDITION_GT:
            lhs << "IF " << tac->X << " > " << tac->Y << " GOTO " << tac->Z;
            break;
        case TAC_TYPE::CONDITION_GE:
            lhs << "IF " << tac->X << " >= " << tac->Y << " GOTO " << tac->Z;
            break;
        case TAC_TYPE::CONDITION_NE:
            lhs << "IF " << tac->X << " != " << tac->Y << " GOTO " << tac->Z;
            break;
        case TAC_TYPE::CONDITION_EQ:
            lhs << "IF " << tac->X << " == " << tac->Y << " GOTO " << tac->Z;
            break;
    }
    return lhs;
}

// 传入 argv[1]
void dump_ir_file(const char *path) {
    ofstream dataFile;
    string path_str = path;
    string newStr = path_str.replace(path_str.size() - 3, 3, "ir");
    dataFile.open(newStr, ofstream::trunc);
    // 朝TXT文档中写入数据
    for (auto *tac: ir_tac) {
        dataFile << tac << endl;
        //delete tac;
    }
    // 关闭文档
    dataFile.close();
}


///// @完成对label的优化
///// @去除连续的label
void label_optimization() {
    vector<TAC *> erase_list;
    string temp;
    int mapper_opt = true;
    TAC_TYPE tac_types[6] = {TAC_TYPE::CONDITION_LT,
                             TAC_TYPE::CONDITION_LE,
                             TAC_TYPE::CONDITION_GT,
                             TAC_TYPE::CONDITION_GE,
                             TAC_TYPE::CONDITION_NE,
                             TAC_TYPE::CONDITION_EQ};
    for (auto *tac: ir_tac) {
        if (tac->type == TAC_TYPE::LABEL) {
            if (mapper_opt == false) {
                for (auto *temp_tac: ir_tac) {
                    if (temp_tac->type == TAC_TYPE::GOTO && temp_tac->X == tac->X) {
                        temp_tac->X = temp;
                    }
                    for (auto &tac_type: tac_types) {
                        if (temp_tac->type == tac_type && temp_tac->Z == tac->X) {
                            temp_tac->Z = temp;
                        }
                    }
                }
                erase_list.push_back(tac);
            } else {
                temp = tac->X;
            }
            mapper_opt = false;
        } else {
            mapper_opt = true;
        }
    }
    auto size = ir_tac.size();
    for (auto *tac: erase_list) {
        std::remove(ir_tac.begin(), ir_tac.end(), tac);
        ir_tac.resize(--size);
    }
}

///// @去除自己对自己赋值的TAC
void duplicated_assign_optimization() {
    if (has_loop) {
        vector<TAC *> erase_list; //待删除指令集合
        for (auto *temp_tac: ir_tac) {
            if (temp_tac->type == TAC_TYPE::ASSIGN) {
                string x = temp_tac->X;
                string y = temp_tac->Y;
                if (x == y
                    && x.find('v') != string::npos     // 两个操作数都是寄存器 包含v
                    && y.find('v') != string::npos) {
                    erase_list.push_back(temp_tac);
                }
            }
        }
        auto size = ir_tac.size();
        for (auto *tac: erase_list) {
            std::remove(ir_tac.begin(), ir_tac.end(), tac);
            ir_tac.resize(--size);
        }
        return;
    } else {

        unordered_map<string, string> reg_mapper; // x -> y
        vector<TAC *> erase_list; //待删除指令集合
        // 当前的优化方法没法优化具有循环的程序

        auto map = [](unordered_map<string, string> mapper, string str) {
            if (mapper.count(str) == 0) {
                return str;
            } else {
                return mapper[str];
            }
        };
        for (auto *temp_tac: ir_tac) {
            if (temp_tac->type == TAC_TYPE::ASSIGN) {
                string x = temp_tac->X;
                string y = temp_tac->Y;
                if (x == y) {
                    erase_list.push_back(temp_tac);
                } else {
                    if (x.find('v') != string::npos     // 两个操作数都是寄存器 包含v
                        && y.find('v') != string::npos) {
                        if (reg_mapper.count(y) != 0) { // 级联映射
                            reg_mapper[x] = reg_mapper[y];
                        } else {
                            reg_mapper[x] = y;
                        }
                        erase_list.push_back(temp_tac);
                    }
                }
            } else {
                temp_tac->X = map(reg_mapper, temp_tac->X);
                temp_tac->Y = map(reg_mapper, temp_tac->Y);
                temp_tac->Z = map(reg_mapper, temp_tac->Z);
            }
        }

        auto size = ir_tac.size();
        for (auto *tac: erase_list) {
            std::remove(ir_tac.begin(), ir_tac.end(), tac);
            ir_tac.resize(--size);
        }
    }
}