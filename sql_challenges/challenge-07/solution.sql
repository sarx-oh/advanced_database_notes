-- Ask something that IS in the article
MY_QUESTION = "What is a word embedding in NLP?"
TOP_N = 3

q_emb = model.encode([MY_QUESTION])[0]
q_vec = format_vector(q_emb)

print(f"-- Search query: {MY_QUESTION}")
print(f"-- Top {TOP_N} most similar chunks")
print()
print("SELECT")
print("    chunk_id,")
print("    SUBSTR(chunk_text, 1, 100) AS preview,")
print(f"    ROUND(VECTOR_DISTANCE(chunk_vector, {q_vec}, COSINE), 4) AS similarity_score")
print("FROM doc_chunks")
print("ORDER BY similarity_score ASC")
print(f"FETCH FIRST {TOP_N} ROWS ONLY;")
--What came back? Does it make sense? Yes, it was a certain parrt of the article


--Ask something that is RELATED but not a direct quote
MY_QUESTION = "How might similar meanings be reflected in the distance between word vectors?"
TOP_N = 3

q_emb = model.encode([MY_QUESTION])[0]
q_vec = format_vector(q_emb)

print(f"-- Search query: {MY_QUESTION}")
print(f"-- Top {TOP_N} most similar chunks")
print()
print("SELECT")
print("    chunk_id,")
print("    SUBSTR(chunk_text, 1, 100) AS preview,")
print(f"    ROUND(VECTOR_DISTANCE(chunk_vector, {q_vec}, COSINE), 4) AS similarity_score")
print("FROM doc_chunks")
print("ORDER BY similarity_score ASC")
print(f"FETCH FIRST {TOP_N} ROWS ONLY;")
--Did it find relevant content even though those exact words aren't in the article? Yes, it was useful information


--Ask something UNRELATED
MY_QUESTION = "How to cook spanish croquetas?"
TOP_N = 3

q_emb = model.encode([MY_QUESTION])[0]
q_vec = format_vector(q_emb)

print(f"-- Search query: {MY_QUESTION}")
print(f"-- Top {TOP_N} most similar chunks")
print()
print("SELECT")
print("    chunk_id,")
print("    SUBSTR(chunk_text, 1, 100) AS preview,")
print(f"    ROUND(VECTOR_DISTANCE(chunk_vector, {q_vec}, COSINE), 4) AS similarity_score")
print("FROM doc_chunks")
print("ORDER BY similarity_score ASC")
print(f"FETCH FIRST {TOP_N} ROWS ONLY;")
--What score did you get? Is it high or low? Why?
--It was kinda high because the is a of the word cook and how to. 0.84
