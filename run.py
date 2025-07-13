import uvicorn
 
if __name__ == "__main__":
    # We run from the parent directory of 'backend'
    # so that Python can treat 'backend' as a package.
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=True) 