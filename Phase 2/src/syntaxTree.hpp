#ifndef _SYBTAX_H
#define _SYBTAX_H

#include <string>
#include <unordered_map>
#include <iterator>
#include "type.hpp"
#include "Node.hpp"
#include "SAUtill.hpp"
#include "semanticError.hpp"

using std::string;
using std::unordered_map;
extern unordered_map<string, Type *> symbolTable;

void print_map_keys();

void idToExp(Node *exp, Node *id);

string getName(Node *node, string nodeName);

Array *getArray(Node *node, Type *type);

void checkExists_ID(Node *node);

void checkExist_FUN(Node *id);

void checkParam_FUN(Node *id, Node *args);

void ExtDefVisit_SES(Node *node);

void ExtDefVisit_SS(Node *node);

void ExtDefVisit_SFC(Node *node);

void Specifier_FunDec_Recv_SF(Node *node);

void getNamesOfDefList(Node *node, vector<Node *> &namesofFileds);

FieldList *getFiledListFromNodesVector(const vector<Node *> &vec);



void FunDecVisit(Node *node);

void getVarList(Node *node);

void getParamDec(Node *node);
// def
void defVisit(Node *node);

void getDecList(Node *node);

void getVarDec(Node *node);

void getReturnTypeOfFunction(Node *expOut, Node *ID);

void checkRvalueInLeftSide(Node *Exp);

void checkAssignmentTypeMatching(Node *leftExp, Node *rightExp);

void checkTypeOfDot(Node *expOut, Node *expIn, Node *ID);

#endif
