package internal

import (
	"context"
	"sync"

	"k8s.io/apimachinery/pkg/runtime"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	ctrl "sigs.k8s.io/controller-runtime"
)

var scheme = runtime.NewScheme()

func init() {
	utilruntime.Must(clientgoscheme.AddToScheme(scheme))
}

type Controller struct {
	mgr ctrl.Manager
}

func (c *Controller) Start(ctx context.Context, wg *sync.WaitGroup, errCh chan<- error) {
	defer wg.Done()

	logger := ctrl.Log.WithName("controller")
	var err error
	c.mgr, err = ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme: scheme,
	})
	if err != nil {
		errCh <- err
		return
	}

	logger.Info("starting manager")
	if err := c.mgr.Start(ctx); err != nil {
		errCh <- err
	}
	logger.Info("manager stopped")
}

func (c *Controller) Shutdown(ctx context.Context) error {
	ctrl.Log.WithName("controller").Info("shutdown called")
	return nil
}
